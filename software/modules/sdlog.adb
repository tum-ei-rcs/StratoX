--  Project: StratoX
--  System:  Stratosphere Balloon Flight Controller
--  Author:  Martin Becker (becker@rcs.ei.tum.de)
with FAT_Filesystem;                   use FAT_Filesystem;
with FAT_Filesystem.Directories;       use FAT_Filesystem.Directories;
with FAT_Filesystem.Directories.Files; use FAT_Filesystem.Directories.Files;
with Media_Reader.SDCard;              use Media_Reader.SDCard;

--  @summary top-level package for reading/writing to SD card
--           minimal package with pointer stuff
package body SDLog with SPARK_Mode => Off is

   SD_Controller   : aliased SDCard_Controller; -- limited type
   FS              : FAT_Filesystem_Access := null; -- pointer
   fh_log          : FAT_Filesystem.Directories.Files.File_Handle;

   -----------
   -- Close --
   -----------

   procedure Close is
   begin
      Close (FS);
      log_open := False;
   end Close;

   ----------
   -- Init --
   ----------

   procedure Init is
      Status : FAT_Filesystem.Status_Code;
   begin
      SD_Initialized := False;
      log_open := False;

      SD_Controller.Initialize;

      if not SD_Controller.Card_Present then
         Error_State := True;
         return;
      else
         Error_State := False;
      end if;

      FS := Open (SD_Controller'Unchecked_Access, Status);

      if Status /= OK then
         Error_State := True;
         return;
      else
         SD_Initialized := True;
      end if;
   end Init;

   -------------------
   -- Start_Logfile --
   -------------------

   --  creates a new directory within root, that is named
   --  after the build.
   procedure Start_Logfile
     (dirname  : String;
      filename : String;
      ret      : out Boolean)
   is
      Hnd_Root : Directory_Handle;
      Status   : Status_Code;
      Log_Dir  : Directory_Entry;
      Log_Hnd  : Directory_Handle;

   begin
      ret := False;
      if (not SD_Initialized) or Error_State then
         return;
      end if;

      if Open_Root_Directory (FS, Hnd_Root) /= OK then
         Error_State := True;
         return;
      end if;

      --  1. create log directory
      Status := Make_Directory (Parent => Hnd_Root,
                                newname => dirname,
                                D_Entry => Log_Dir);
      if Status /= OK and then Status /= Already_Exists
      then
         return;
      end if;
      Close (Hnd_Root);

      Status := Open (E => Log_Dir, Dir => Log_Hnd);
      if Status /= OK then
         return;
      end if;

      --  2. create log file
      Status := File_Create (Parent => Log_Hnd,
                             newname => filename,
                             File => fh_log);
      if Status /= OK then
         return;
      end if;

      ret := True;
      log_open := True;
   end Start_Logfile;

   ---------------
   -- Flush_Log --
   ---------------

   procedure Flush_Log is
   begin
      if not log_open then
         return;
      end if;
      declare
         Status : Status_Code := File_Flush (fh_log);
         pragma Unreferenced (Status);
      begin
         null;
      end;
   end Flush_Log;

   ---------------
   -- Write_Log --
   ---------------

   procedure Write_Log
     (Data      : FAT_Filesystem.Directories.Files.File_Data;
      n_written : out Integer) is
   begin
      if not log_open then
         n_written := -1;
         return;
      end if;
      declare
         DISCARD : Status_Code;
      begin
         n_written := File_Write
           (File => fh_log, Data => Data, Status => DISCARD);
      end;
   end Write_Log;

   procedure Write_Log (S : String; n_written : out Integer) is
      d : File_Data renames To_File_Data (S);
   begin
      Write_Log (d, n_written);
   end Write_Log;

   ------------------
   -- To_File_Data --
   ------------------

   function To_File_Data
     (S : String) return FAT_Filesystem.Directories.Files.File_Data
   is
      d   : File_Data (1 .. S'Length);
      idx : Unsigned_16 := d'First;
   begin
      --  FIXME: inefficient
      for k in S'Range loop
         d (idx) := Character'Pos (S (k));
         idx := idx + 1;
      end loop;
      return d; -- this throws an exception.
   end To_File_Data;

   function Is_Open return Boolean is (log_open);

   function Logsize return Unsigned_32 is (File_Size (fh_log));

end SDLog;
