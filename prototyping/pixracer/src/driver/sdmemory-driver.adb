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
   SD_Card_Info  : Card_Information;
   Error_State   : Boolean := False;
   FS            : FAT_Filesystem_Access;
   SD_Initialized   : Boolean := False;

   procedure Close_Filesys is
   begin
      if not SD_Initialized then
         return;
      end if;

      Close (FS);
   end Close_Filesys;

   procedure Init_Filesys is
      Units    : constant array (Natural range <>) of Character :=
        (' ', 'k', 'M', 'G', 'T');
      Capacity : Unsigned_64;
      Status   : FAT_Filesystem.Status_Code;
   begin
      SD_Controller.Initialize;

      if not SD_Controller.Card_Present then
         Logger.log (Logger.ERROR, "Please insert SD card");
         Error_State := True;
      else
         Error_State := False;
      end if;

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
      SD_Initialized := True;
   end Init_Filesys;

   procedure Make_Logdir (dirname : String) is
      Dir_Root : Directory_Handle;
      Dir_Log  : Directory_Handle;
   begin
      if (not SD_Initialized) or Error_State then
         return;
      end if;

      if Open_Root_Directory (FS, Dir_Root) /= OK then
         Error_State := True;
         return;
      end if;

--        if Make_Directory (Parent => Dir_Root,
--                           newname => dirname,
--                           Dir => Dir_Log) /= OK
--        then
--           Logger.log (Logger.ERROR, "SD Card: Error creating directory in root");
--        else
--           Logger.log (Logger.INFO, "SD Card: Created directory /" & dirname);
--        end if;
      Close (Dir_Root);

   end Make_Logdir;

   procedure List_Rootdir is
      Dir : Directory_Handle;
      Ent : Directory_Entry;
   begin

      if (not SD_Initialized) or Error_State then
         return;
      end if;

      Logger.log (Logger.INFO, "SD Card: " & Volume_Label (FS.all) &
                    " (" & File_System_Type (FS.all) & ")");

      if Open_Root_Directory (FS, Dir) /= OK then
         Logger.log (Logger.ERROR, "SD Card: Error reading root");
         Error_State := True;
         return;
      end if;

      Logger.log (Logger.INFO, "SD Card listing:");
      while Read (Dir, Ent) = OK loop
         if Is_System_File (Ent) then
            declare
               Contents : String (1 .. 16);
            begin
               --  TODO: read first 16 bytes of file
               Logger.log (Logger.INFO, " +- " & Name (Ent) & ": " & Contents);
            end;
         else
            Logger.log (Logger.INFO, " +- " & Name (Ent) & (if Is_Subdirectory (Ent) then "/" else ""));
         end if;
      end loop;
      Close (Dir);
   end List_Rootdir;
end SDMemory.Driver;
