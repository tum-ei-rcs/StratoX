--  Project: StratoX
--  System:  Stratosphere Balloon Flight Controller
--  Author:  Martin Becker (becker@rcs.ei.tum.de)
with Profiler;
with Ada.Real_Time; use Ada.Real_Time;
with Logger;
with Units;
with FAT_Filesystem;                   use FAT_Filesystem;
with FAT_Filesystem.Directories;       use FAT_Filesystem.Directories;
with FAT_Filesystem.Directories.Files; use FAT_Filesystem.Directories.Files;

--  @summary tools for SD Logging
package body SDLog.Tools with SPARK_Mode => Off is

   ENDL : constant Character := Character'Val (10);

   --------------------
   --  Perf_Test
   --------------------

   procedure Perf_Test (FS : in FAT_Filesystem_Access; megabytes : Unsigned_32) is
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
            Logger.log_console (Logger.INFO, "Time=" & Integer (lapsed)'Img & ", xfer="
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
      Logger.log_console (Logger.INFO, "Write performance test with " & megabytes'Img & " MB" & ENDL);

      if (not SDLog.SD_Initialized) or SDLog.Error_State then
         Logger.log_console (Logger.ERROR, "SD Card not initialized" & ENDL);
         return;
      end if;

      if Open_Root_Directory (FS, Hnd_Root) /= OK then
         Logger.log_console (Logger.INFO, "Error opening root dir" & ENDL);
         return;
      end if;

      prof.init ("perf");

      --  open a file
      Status := File_Create (Parent => Hnd_Root,
                             newname => "perf.dat",
                             Overwrite => True,
                             File => fh_perf);
      if Status /= OK then
         Logger.log_console (Logger.ERROR,
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
                  Logger.log_console (Logger.ERROR, "Perf write error" & Image (Status));
               else
                  Logger.log_console (Logger.ERROR, "Perf wrote only " & n_written'Img
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

   ------------------
   --  List_Rootdir
   ------------------

   procedure List_Rootdir (FS : in FAT_Filesystem_Access) is
      Dir : Directory_Handle;
      Ent : Directory_Entry;
   begin

      if (not SDLog.SD_Initialized) or SDLog.Error_State then
         return;
      end if;

      Logger.log_console (Logger.INFO, "SD Card: " & Volume_Label (FS.all) &
                    " (" & File_System_Type (FS.all) & ")");

      if Open_Root_Directory (FS, Dir) /= OK then
         Logger.log_console (Logger.ERROR, "SD Card: Error reading root");
         Error_State := True;
         return;
      end if;

      Logger.log_console (Logger.INFO, "SD Card listing:");
      while Read (Dir, Ent) = OK loop
         if Is_System_File (Ent) then
            declare
               Contents : String (1 .. 16);
               pragma Unreferenced (Contents); -- later, when File_Read works.
            begin
               Logger.log_console (Logger.INFO, " +- " & Get_Name (Ent));
            end;
         else
            Logger.log_console (Logger.INFO, " +- " & Get_Name (Ent) &
                        (if Is_Subdirectory (Ent) then "/" else ""));
         end if;
      end loop;
      Close (Dir);
      pragma Unreferenced (Dir);
   end List_Rootdir;

end SDLog.Tools;
