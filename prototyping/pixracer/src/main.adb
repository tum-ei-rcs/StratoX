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

package body Main is

   ENDL : constant String := (Character'Val (13), Character'Val (10));

   procedure Initialize is
      success : Boolean := False;
      t_next  : Ada.Real_Time.Time;
      logret  : Logger.Init_Error_Code;
   begin
      CPU.initialize;

      Logger.init (logret);
      Logger.log (Logger.INFO, "---------------");
      Logger.log (Logger.INFO, "CPU initialized");

      Buzzer_Manager.Initialize;

      LED_Manager.LED_switchOff;
      LED_Manager.Set_Color ((HIL.Devices.RED_LED => True, HIL.Devices.GRN_LED => False, HIL.Devices.BLU_LED => False));
      LED_Manager.LED_switchOn;

      Logger.log (Logger.INFO, "Initializing SDIO...");

      Logger.log (Logger.INFO, "Initializing NVRAM...");
      NVRAM.Init;

      Logger.log (Logger.INFO, "Start SD Logging...");
      Logger.Start_SDLog;

      --  self checks
      Logger.log (Logger.INFO, "Self-Check NVRAM...");
      NVRAM.Self_Check (Status => success);

      --  hang here if self-checks failed
      if not success then
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

      LED_Manager.Set_Color ((HIL.Devices.RED_LED => True, HIL.Devices.GRN_LED => True, HIL.Devices.BLU_LED => False));
      LED_Manager.LED_switchOn;
      SDLog.Perf_Test (10);
      Logger.log (Logger.INFO, "SD Card check done");
   end Initialize;


   procedure Run_Loop is
      --  data    : HIL.SPI.Data_Type (1 .. 3)  := (others => 0);
      --  data_rx : HIL.UART.Data_Type (1 .. 1) := (others => 0);
      loop_time_start   : Time      := Clock;

      --      gleich : Ada.Real_Time.Time;
      --      song : constant Buzzer_Manager.Song_Type := (('c',6),('d',6),('c',6),('f',6));
      type prescaler is mod 100;
      p : prescaler := 0;
   begin
      LED_Manager.Set_Color ((HIL.Devices.RED_LED => False, HIL.Devices.GRN_LED => False, HIL.Devices.BLU_LED => False));
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
