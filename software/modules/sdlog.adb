--  Project: StratoX
--  System:  Stratosphere Balloon Flight Controller
--  Author:  Martin Becker (becker@rcs.ei.tum.de)
with Ada.Real_Time;                    use Ada.Real_Time;
with STM32.SDMMC;                      use STM32.SDMMC;
with FAT_Filesystem;                   use FAT_Filesystem;
with FAT_Filesystem.Directories;       use FAT_Filesystem.Directories;
with FAT_Filesystem.Directories.Files; use FAT_Filesystem.Directories.Files;
with Media_Reader.SDCard;              use Media_Reader.SDCard;
with Logger;
with Profiler;
with Units;

--  @summary top-level package for reading/writing to SD card
package body SDLog with SPARK_Mode => Off is

   SD_Controller   : aliased SDCard_Controller;
   SD_Card_Info    : Card_Information;
   Error_State     : Boolean := False;
   FS              : FAT_Filesystem_Access;
   SD_Initialized  : Boolean := False;

   fh_log   : File_Handle;
   log_open : Boolean := False;

   ENDL : constant String := (Character'Val (13), Character'Val (10));

   -------------------
   --  Close_Filesys
   -------------------

   procedure Close is
   begin
      if not SD_Initialized then
         return;
      end if;

      Close (FS);
   end Close;

   -------------------
   --  Init_Filesys
   -------------------

   procedure Init is
      Size_Units : constant array (Natural range <>) of Character :=
        (' ', 'k', 'M', 'G', 'T');
      Capacity   : Unsigned_64;
      Status     : FAT_Filesystem.Status_Code;
   begin
      SD_Controller.Initialize;

      if not SD_Controller.Card_Present then
         Logger.log (Logger.ERROR, "Please insert SD card");
         Error_State := True;
         return;
      else
         Error_State := False;
      end if;

      SD_Card_Info := SD_Controller.Get_Card_Information;

      --  Dump general info about the SD-card
      Capacity := SD_Card_Info.Card_Capacity;

      --  human-readable units
      for Unit of Size_Units loop
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
   end Init;

   -------------------
   --  Start_Logfile
   -------------------

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
                       Image (Status));
         return False;
      end if;
      Close (Hnd_Root);

      Status := Open (E => Log_Dir, Dir => Log_Hnd);
      if Status /= OK then
         Logger.log (Logger.ERROR,
                     "SD Card: Error opening log dir in root:" &
                       Image (Status));
         return False;
      end if;

      --  2. create log file
      Status := File_Create (Parent => Log_Hnd,
                             newname => filename,
                             File => fh_log);
      if Status /= OK then
         Logger.log (Logger.ERROR,
                     "SD Card: Error creating log file:" &
                       Image (Status));
         return False;
      end if;
      log_open := True;
      return True;
   end Start_Logfile;

   ------------------
   --  List_Rootdir
   ------------------

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
               pragma Unreferenced (Contents); -- later, when File_Read works.
            begin
               Logger.log (Logger.INFO, " +- " & Get_Name (Ent));
            end;
         else
            Logger.log (Logger.INFO, " +- " & Get_Name (Ent) &
                        (if Is_Subdirectory (Ent) then "/" else ""));
         end if;
      end loop;
      Close (Dir);
      pragma Unreferenced (Dir);
   end List_Rootdir;

   ---------------
   --  Flush_Log
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
   --  Write_Log
   ---------------

   procedure Write_Log (Data : FAT_Filesystem.Directories.Files.File_Data) is
   begin
      if not log_open then
         return;
      end if;
      declare
         Status : Status_Code;
         n_written : constant Integer := File_Write (File => fh_log, Data => Data, Status => Status);
      begin
         if n_written < Data'Length then
            if n_written < 0 then
               Logger.log (Logger.ERROR, "Logfile write error" & Image (Status));
            else
               Logger.log (Logger.ERROR, "Logfile wrote only " & n_written'Img
                           & " bytes instead of " & Data'Length'Img
                           & "(" & Image (Status) & ")");
            end if;
         end if;
      end;
   end Write_Log;

   procedure Write_Log (S : String) is
      d : File_Data renames To_File_Data (S);
   begin
      Write_Log (d);
   end Write_Log;

   ------------------
   --  To_File_Data
   ------------------

   function To_File_Data (S : String) return FAT_Filesystem.Directories.Files.File_Data is
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

   --------------------
   --  Perf_Test
   --------------------
   procedure Perf_Test (megabytes : Unsigned_32) is
      dummydata  : FAT_Filesystem.Directories.Files.File_Data (1 .. 1024);
      TARGETSIZE : constant Unsigned_32 := megabytes * 1024 * 1024;
      filesize   : Unsigned_32;
      filesize_pre : Unsigned_32 := SDLog.Logsize;
      lapsed_pre : Float := 0.0;
      prof : Profiler.Profile_Tag;

      procedure Show_Stats;
      procedure Show_Stats is
         ts     : constant Time_Span := prof.get_Elapsed;
         lapsed : constant Float := Float (Units.To_Time (ts));
         diff   : constant Float := lapsed - lapsed_pre;
         bps    : Integer;
         cps    : Integer;
      begin

         if diff > 0.0 then
            cps := Integer (1000.0 / diff);
            bps := Integer (Float (filesize - filesize_pre) / diff);
            Logger.log (Logger.INFO, "Time=" & Integer (lapsed)'Img & ", xfer="
                        & filesize'Img & "=>" & bps'Img & " B/s " & cps'Img & " calls/s");
            filesize_pre := filesize;
            lapsed_pre := lapsed;
         end if;
      end Show_Stats;

      type prescaler is mod 1000;
      ctr      : prescaler := 0;
      fh_perf  : File_Handle;
      Hnd_Root : Directory_Handle;
      Status   : Status_Code;
   begin
      Logger.log (Logger.INFO, "Write performance test with " & megabytes'Img & " MB" & ENDL);

      if (not SD_Initialized) or Error_State then
         Logger.log (Logger.ERROR, "SD Card not initialized" & ENDL);
         return;
      end if;

      if Open_Root_Directory (FS, Hnd_Root) /= OK then
         Logger.log (Logger.INFO, "Error opening root dir" & ENDL);
         return;
      end if;

      prof.init ("perf");

      --  open a file
      Status := File_Create (Parent => Hnd_Root,
                             newname => "perf.dat",
                             Overwrite => True,
                             File => fh_perf);
      if Status /= OK then
         Logger.log (Logger.ERROR,
                     "SD Card: Error creating file:" & Image (Status));
         return;
      end if;

      prof.start;
      Write_Loop :
      loop
         filesize := File_Size (fh_perf);

         declare
            n_written : constant Integer := File_Write (fh_perf, dummydata, Status);
         begin
            if n_written < dummydata'Length then
               if n_written < 0 then
                  Logger.log (Logger.ERROR, "Perf write error" & Image (Status));
               else
                  Logger.log (Logger.ERROR, "Perf wrote only " & n_written'Img
                              & " bytes instead of " & dummydata'Length'Img
                              & "(" & Image (Status) & ")");
               end if;
            end if;
         end;

         if ctr = 0 then
            Show_Stats;
         end if;
         ctr := ctr + 1;

         exit Write_Loop when filesize >= TARGETSIZE;
      end loop Write_Loop;
      File_Close (fh_perf);
      prof.stop;
      Show_Stats;

   end Perf_Test;

end SDLog;
