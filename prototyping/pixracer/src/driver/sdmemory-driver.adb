--  with Ada.Unchecked_Conversion;
with Interfaces;                 use Interfaces;

with STM32.SDMMC;                use STM32.SDMMC;
--  with STM32.Board;                use STM32.Board;

with FAT_Filesystem;             use FAT_Filesystem;
with FAT_Filesystem.Directories; use FAT_Filesystem.Directories;
with Media_Reader.SDCard;        use Media_Reader.SDCard;
with Logger;

package body SDMemory.Driver is

   SD_Controller : aliased SDCard_Controller;

   procedure Init_Filesys is
   begin
      SD_Controller.Initialize;
   end Init_Filesys;

   procedure List_Rootdir is
      SD_Card_Info  : Card_Information;

      Units         : constant array (Natural range <>) of Character :=
        (' ', 'k', 'M', 'G', 'T');
      Capacity      : Unsigned_64;
      Error_State   : Boolean := False;

      FS             : FAT_Filesystem_Access;

      Status         : FAT_Filesystem.Status_Code;

      Dir            : Directory_Handle;
      Ent            : Directory_Entry;

   begin

      if not SD_Controller.Card_Present then
         Logger.log (Logger.ERROR, "Please insert SD card");

         loop
            if Card_Present (SD_Controller) then
               exit;
            end if;
         end loop;

      else
         Error_State := False;

         SD_Card_Info := SD_Controller.Get_Card_Information;

         --  Dump general info about the SD-card
         Capacity := SD_Card_Info.Card_Capacity;

         --  human-readable units
         for Unit of Units loop
            if Capacity < 1000 or else Unit = 'T' then
               Logger.log (Logger.INFO, "SD card size:" & Capacity'Img & " " & Unit & "B");
               exit;
            end if;

            if Capacity mod 1000 >= 500 then
               Capacity := Capacity / 1000 + 1;
            else
               Capacity := Capacity / 1000;
            end if;
         end loop;

         Logger.log (Logger.DEBUG, "Opening SD Filesys...");
         FS := Open (SD_Controller'Unchecked_Access, Status);

         if Status /= OK then
            Error_State := True;

            if Status = No_MBR_Found then
               Logger.log (Logger.ERROR, "SD Card: No MBR found");
            elsif Status = No_Partition_Found then
               Logger.log (Logger.ERROR, "SD Card: No Partition found");
            else
               Logger.log (Logger.ERROR, "SD Card: Error reading card");
               --  Error reading the card: & Status'Img
               null;
            end if;
         else
            Logger.log (Logger.DEBUG, "SD Card: found FAT FS");
         end if;

         if not Error_State then
            Logger.log (Logger.INFO, "SD Card: " & Volume_Label (FS.all) &
                          " (" & File_System_Type (FS.all) & ")");

            if Open_Root_Directory (FS, Dir) /= OK then
               Logger.log (Logger.ERROR, "SD Card: Error reading root");
               Close (FS);
               Error_State := True;
            end if;
         end if;

         if not Error_State then
            Logger.log (Logger.INFO, "SD Card listing:");
            while Read (Dir, Ent) = OK loop
               Logger.log (Logger.INFO, " +- " & Name (Ent) & (if Is_Subdirectory (Ent) then "/" else ""));
            end loop;
            Close (Dir);
            Close (FS);
         end if;
      end if;

   end List_Rootdir;
end SDMemory.Driver;
