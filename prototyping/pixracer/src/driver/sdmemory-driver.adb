--  with Ada.Unchecked_Conversion;
with Interfaces;                 use Interfaces;

with STM32.SDMMC;                      use STM32.SDMMC;

with FAT_Filesystem;                   use FAT_Filesystem;
with FAT_Filesystem.Directories;       use FAT_Filesystem.Directories;
with FAT_Filesystem.Directories.Files; use FAT_Filesystem.Directories.Files;
with Media_Reader.SDCard;              use Media_Reader.SDCard;
with Logger;

package body SDMemory.Driver is

   SD_Controller : aliased SDCard_Controller;
   SD_Card_Info  : Card_Information;
   Error_State   : Boolean := False;
   FS            : FAT_Filesystem_Access;
   SD_Initialized   : Boolean := False;

   fh_log   : File_Handle;
   log_open : Boolean := False;

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

   --  creates a new directory within root, that is named
   --  after the build.
   function Start_Logfile (dirname : String; filename : String) return Boolean is
      Hnd_Root : Directory_Handle;
      Status   : Status_Code;
      Log_Dir  : Directory_Entry;
      Log_Hnd  : Directory_Handle;
   begin
      if (not SD_Initialized) or Error_State then
         return False;
      end if;

      if Open_Root_Directory (FS, Hnd_Root) /= OK then
         Error_State := True;
         return False;
      end if;

      --  1. create log directory
      Status := Make_Directory (Parent => Hnd_Root,
                                newname => dirname,
                                D_Entry => Log_Dir);
      if Status /= OK and then Status /= Already_Exists
      then
         Logger.log (Logger.ERROR,
                     "SD Card: Error creating directory in root:" &
                       Status'Img);
         return False;
      end if;
      Close (Hnd_Root);

      Status := Open (E => Log_Dir, Dir => Log_Hnd);
      if Status /= OK then
         Logger.log (Logger.ERROR,
                     "SD Card: Error opening log dir in root:" &
                       Status'Img);
         return False;
      end if;

      --  2. create log file
      Status := File_Create (Parent => Log_Hnd,
                             newname => filename,
                             File => fh_log);
      if Status /= OK then
         Logger.log (Logger.ERROR,
                     "SD Card: Error creating log file:" &
                       Status'Img);
         return False;
      end if;
      log_open := True;
      return True;
   end Start_Logfile;

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
               Logger.log (Logger.INFO, " +- " & Get_Name (Ent) & ": " & Contents);
            end;
         else
            Logger.log (Logger.INFO, " +- " & Get_Name (Ent) &
                        (if Is_Subdirectory (Ent) then "/" else ""));
         end if;
      end loop;
      Close (Dir);
   end List_Rootdir;
end SDMemory.Driver;
