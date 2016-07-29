--  Description: PIXRACER PROTOTYPING MAIN FILE
--  Main System File
--  todo: better unit name

with Ada.Real_Time; use Ada.Real_Time;
with Config;        use Config;
with Interfaces;    use Interfaces;
with CPU;
with HIL.Devices;
with NVRAM;
with Logger;
with LED_Manager;
with Buzzer_Manager;
with SDLog;
with Buildinfo;
with FAT_Filesystem.Directories.Files; -- actually not necessary

package body Main is

   ENDL : constant String := (Character'Val (13), Character'Val (10));

   procedure Perf_Test (megabytes : Unsigned_32);

   procedure Initialize is
      success : Boolean := False;
      t_next  : Ada.Real_Time.Time;
      logret  : Logger.Init_Error_Code;
      bootcounter : HIL.Byte;
   begin
      CPU.initialize;

      Logger.init (logret);
      Logger.log (Logger.INFO, "---------------");
      Logger.log (Logger.INFO, "CPU initialized");

      Buzzer_Manager.Initialize;

      LED_Manager.LED_switchOff;
      LED_Manager.Set_Color ((1 => HIL.Devices.RED_LED));
      LED_Manager.LED_switchOn;

      Logger.log (Logger.INFO, "Initializing SDIO...");
      SDLog.Init;

      Logger.log (Logger.INFO, "Initializing NVRAM...");
      NVRAM.Init;

      --  self checks
      Logger.log (Logger.INFO, "Self-Check NVRAM...");
      NVRAM.Self_Check (Status => success);

      --  hang here if self-checks failed
      if not success then
         LED_Manager.Set_Color ((1 => HIL.Devices.RED_LED));
         LED_Manager.LED_blink (LED_Manager.FAST);
         Logger.log (Logger.ERROR, "Self checks failed");
         t_next := Clock;
         loop
            LED_Manager.LED_tick (Config.MAIN_TICK_RATE_MS);
            LED_Manager.LED_sync;

            delay until t_next;
            t_next := t_next + Milliseconds (Config.MAIN_TICK_RATE_MS);
         end loop;
      else
         Logger.log (Logger.INFO, "Self checks passed");
         delay until Clock + Milliseconds (50);
      end if;

      NVRAM.Load (variable => NVRAM.VAR_BOOTCOUNTER, data => bootcounter);
      bootcounter := bootcounter + 1;
      Logger.log (Logger.INFO, "Build Date: " & Buildinfo.Compilation_Date &
                    " " & Buildinfo.Compilation_Time);
      Logger.log (Logger.INFO, "Bootcount:  " & HIL.Byte'Image (bootcounter));
      NVRAM.Store (variable => NVRAM.VAR_BOOTCOUNTER, data => bootcounter);

      Logger.log (Logger.INFO, "SD Card check...");
      SDLog.List_Rootdir;
      declare
         buildstring : constant String := Buildinfo.Short_Datetime;
         fname : constant String := bootcounter'Img & ".log";
      begin
         if not SDLog.Start_Logfile (dirname => buildstring, filename => fname)
         then
            Logger.log (Logger.ERROR, "Cannot create logfile: " & buildstring & "/" & fname);
         else
            Logger.log (Logger.INFO, "Log name: " & buildstring & "/" & fname);
            SDLog.Write_Log ("Build Stamp: "
                                       & Buildinfo.Compilation_Date & " "
                                       & Buildinfo.Compilation_Time & ENDL);
            SDLog.Flush_Log;
         end if;
         null;
      end;
      --  Perf_Test (20); --> crash
      Logger.log (Logger.INFO, "SD Card check done");
   end Initialize;

   procedure Perf_Test (megabytes : Unsigned_32) is
      time_start : constant Time := Clock;
      dummydata  : FAT_Filesystem.Directories.Files.File_Data (1 .. 512);
      TARGETSIZE : constant Unsigned_32 := megabytes * 1024 * 1024;
      filesize   : Unsigned_32;
      filesize_pre : Unsigned_32 := SDLog.Logsize;

      s0         : Seconds_Count;
      ts         : Time_Span;

      procedure Show_Stats;
      procedure Show_Stats is
         s          : Seconds_Count;
         lapsed     : Seconds_Count;
         bps        : Integer;
         time_now   : constant Time := Clock;
      begin
         Split (T => time_now, SC => s, TS => ts);
         lapsed := s0 - s;
         if lapsed > 0 then
            bps := Integer (Float (filesize - filesize_pre) / Float (lapsed));
            Logger.log (Logger.INFO, "Time=" & lapsed'Img & ", xfer="
                        & filesize'Img & "=>" & bps'Img & " B/s");
            filesize_pre := filesize;
         end if;
      end Show_Stats;

      type prescaler is mod 1000;
      ctr : prescaler := 0;
   begin
      Logger.log (Logger.INFO, "Write performance test with " & megabytes'Img & " MB" & ENDL);
      Split (T => time_start, SC => s0, TS => ts);

      Write_Loop :
      loop
         filesize := SDLog.Logsize;

         SDLog.Write_Log (dummydata);

         if ctr = 0 then
            Show_Stats;
         end if;
         ctr := ctr + 1;

         exit Write_Loop when filesize >= TARGETSIZE;
      end loop Write_Loop;
      Show_Stats;

   end Perf_Test;

   procedure Run_Loop is
      --  data    : HIL.SPI.Data_Type (1 .. 3)  := (others => 0);
      --  data_rx : HIL.UART.Data_Type (1 .. 1) := (others => 0);
      loop_time_start   : Time      := Clock;

      --      gleich : Ada.Real_Time.Time;
      --      song : constant Buzzer_Manager.Song_Type := (('c',6),('d',6),('c',6),('f',6));
      type prescaler is mod 100;
      p : prescaler := 0;
   begin
      LED_Manager.Set_Color ((1 => HIL.Devices.GRN_LED));
      LED_Manager.LED_blink (LED_Manager.SLOW);

--        Buzzer_Manager.Set_Timing (period => 0.5 * Second, length => 0.1 * Second); -- gapless
--        Buzzer_Manager.Enable;
--
--        gleich := Clock;
--        for x in 1 .. song'Length loop
--           Buzzer_Manager.Set_Tone (song (x));
--           Buzzer_Manager.Tick;
--           gleich := gleich + Milliseconds(250);
--           delay until gleich;
--           Buzzer_Manager.Tick;
--        end loop;
--        Buzzer_Manager.Disable;


      loop
         loop_time_start := Clock;

         p := p + 1;
         if p = 0 then
            Logger.log (Logger.INFO, "Logfile size " & SDLog.Logsize'Img & " B");
         end if;

         declare
            s  : Seconds_Count;
            ts : Time_Span;
            ticks : Integer;
            si : constant Unsigned_32 := SDLog.Logsize;
         begin
            Split (T => loop_time_start, SC => s, TS => ts);
            ticks := ts / Ada.Real_Time.Tick;
            SDLog.Write_Log ("Time:" & s'Img & "/" & ticks'Img
                                       & ", size:" & si'Img & ENDL);
         end;

         --  LED heartbeat
         LED_Manager.LED_tick (MAIN_TICK_RATE_MS);
         LED_Manager.LED_sync;
         --  Buzzer_Manager.Tick;

--           --  UART Test
--           --  HIL.UART.write(HIL.UART.Console, (70, 65) );
--           HIL.UART.read (HIL.UART.Console, data_rx);
--
--           case (Character'Val (data_rx (1))) is
--
--              when 'l' =>
--                 LED_Manager.LED_blink (LED_Manager.FAST);
--              when 'd' =>
--                 null;
--                 --  PX4IO.Driver.disarm;
--              when 'p' =>
--                 Logger.log
--                   (Logger.INFO,
--                    Integer'Image (loop_duration_max / Time_Span_Unit));
--              when others =>
--                 null;
--           end case;


         --  SPI Test
         --  HIL.SPI.select_Chip(HIL.SPI.Extern);
         --  HIL.SPI.transfer(HIL.SPI.Extern, (166, 0, 0), data );
         --  HIL.SPI.deselect_Chip(HIL.SPI.Extern);

         --  wait remaining loop time
         delay until loop_time_start + Milliseconds (MAIN_TICK_RATE_MS);
      end loop;
   end Run_Loop;

end Main;
