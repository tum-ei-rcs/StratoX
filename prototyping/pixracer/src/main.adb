--  Description: PIXRACER PROTOTYPING MAIN FILE
--  Main System File

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
with ULog;
with STM32.DWT;

package body Main is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      success : Boolean := False;
      t_next  : Ada.Real_Time.Time;
      logret  : Logger.Init_Error_Code;
   begin
      CPU.initialize;

      Logger.Init (logret);
      Logger.log_console (Logger.INFO, "---------------");
      Logger.log_console (Logger.INFO, "CPU initialized");

      Buzzer_Manager.Initialize;

      LED_Manager.LED_switchOff;
      LED_Manager.Set_Color
        ((HIL.Devices.RED_LED => True,
          HIL.Devices.GRN_LED => False,
          HIL.Devices.BLU_LED => False));
      LED_Manager.LED_switchOn;

      Logger.log_console (Logger.INFO, "Initializing NVRAM...");
      NVRAM.Init;

      if With_SD_Log then
         Logger.log_console (Logger.INFO, "Start SD Logging...");
         Logger.Start_SDLog;
      else
         Logger.log_console (Logger.INFO, "SD Log disabled in config.");
      end if;

      --  self checks
      Logger.log_console (Logger.INFO, "Self-Check NVRAM...");
      NVRAM.Self_Check (Status => success);

      --  hang here if self-checks failed
      if not success then
         LED_Manager.LED_blink (LED_Manager.FAST);
         Logger.log_console (Logger.ERROR, "Self checks failed");
         t_next := Clock;
         loop
            LED_Manager.LED_tick (Config.MAIN_TICK_RATE_MS);
            LED_Manager.LED_sync;

            delay until t_next;
            t_next := t_next + Milliseconds (Config.MAIN_TICK_RATE_MS);
         end loop;
      else
         Logger.log_console (Logger.INFO, "Self checks passed");
         delay until Clock + Milliseconds (50);
      end if;

      LED_Manager.Set_Color
        ((HIL.Devices.RED_LED => True,
          HIL.Devices.GRN_LED => True,
          HIL.Devices.BLU_LED => False));
      LED_Manager.LED_switchOn;
   end Initialize;

   --------------
   -- Run_Loop --
   --------------

   procedure Run_Loop is
      loop_period : constant Time_Span := Milliseconds (MAIN_TICK_RATE_MS);
      loop_next   : Time      := Clock;

      --  gleich : Ada.Real_Time.Time;
      --  song : constant Buzzer_Manager.Song_Type :=
      --  (('c',6),('d',6),('c',6),('f',6));
      PRESCALER : constant := 100;
      type prescaler_t is mod PRESCALER;
      p : prescaler_t := 0;

      type prescaler_gps is mod 20;
      pg : prescaler_gps := 0;
      mgps : ULog.Message (ULog.GPS);

      --  loop measurements
      cycle_begin : Unsigned_32;
      cycles_sum  : Unsigned_32 := 0;
      cycles_avg  : Unsigned_32;
      cycles_min  : Unsigned_32 := Unsigned_32'Last;
      cycles_max  : Unsigned_32 := Unsigned_32'First;
   begin
      LED_Manager.Set_Color
        ((HIL.Devices.RED_LED => False,
          HIL.Devices.GRN_LED => True,
          HIL.Devices.BLU_LED => False));
      LED_Manager.LED_blink (LED_Manager.SLOW);

      --  Buzzer_Manager.Set_Timing
      --  (period => 0.5 * Second, length => 0.1 * Second);
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

      --  gps initial
      mgps.lat       := 48.15;
      mgps.lon       := 11.583;
      mgps.alt       := 560.0;
      mgps.gps_year  := 1908;
      mgps.gps_month := 1;
      mgps.gps_sec   := 0;
      mgps.fix       := 0;
      mgps.nsat      := 8;

      loop
         cycle_begin := STM32.DWT.Read_Cycle_Counter;
         p := p + 1;

         --  LED heartbeat
         LED_Manager.LED_tick (MAIN_TICK_RATE_MS);
         LED_Manager.LED_sync;

         --  SD card test
         if With_SD_Log then
            if p = 0 then
               Logger.log_console
                 (Logger.INFO, "Logfile size " & SDLog.Logsize'Img & " B");
            end if;

            --  fake GPS message to test SD log
            pg := pg + 1;
            if pg = 0 then
               mgps.t := Ada.Real_Time.Clock;
               mgps.lat := mgps.lat - 0.1;
               mgps.gps_sec := mgps.gps_sec + 1;

               Logger.log_sd (msg_level => Logger.SENSOR, message => mgps);
            end if;
         end if;

         --  cycle counter
         declare
            cycle_end   : constant Unsigned_32 := STM32.DWT.Read_Cycle_Counter;
            cycles_loop : constant Unsigned_32 := cycle_end - cycle_begin;
         begin
            cycles_sum := cycles_sum + cycles_loop;
            cycles_min := (if cycles_loop < cycles_min then
                              cycles_loop else cycles_min);
            cycles_max := (if cycles_loop > cycles_max then
                              cycles_loop else cycles_max);

            if p = 0 then
               --  output
               cycles_avg := cycles_sum / PRESCALER;
               Logger.log_console
                 (Logger.INFO, "Loop min/avg/max cyc: " &
                    Unsigned_32'Image (cycles_min) &
                    Unsigned_32'Image (cycles_avg) &
                    Unsigned_32'Image (cycles_max));
               --  reset
               cycles_sum := 0;
               cycles_min := Unsigned_32'Last;
               cycles_max := Unsigned_32'First;
            end if;
         end;

         --  wait remaining loop time
         loop_next := loop_next + loop_period;
         delay until loop_next;
      end loop;
   end Run_Loop;

end Main;
