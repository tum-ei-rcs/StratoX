--  Description:
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

package body Main is

   procedure Initialize is
      success : Boolean := False;
      t_next  : Ada.Real_Time.Time;
      logret  : Logger.Init_Error_Code;
   begin
      CPU.initialize;
      Logger.init (logret);
      Logger.log (Logger.INFO, "---------------");
      Logger.log (Logger.INFO, "CPU initialized");

      LED_Manager.Set_Color ((1 => HIL.Devices.RED_LED));
      LED_Manager.LED_switchOn;

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
   end Initialize;

   procedure Run_Loop is
      --  data    : HIL.SPI.Data_Type (1 .. 3)  := (others => 0);
      --  data_rx : HIL.UART.Data_Type (1 .. 1) := (others => 0);
      loop_time_start   : Time      := Clock;
      bootcounter : HIL.Byte;

      function Compilation_Date return String -- implementation-defined (GNAT)
        with Import, Convention => Intrinsic;
      function Compilation_Time return String -- implementation-defined (GNAT)
        with Import, Convention => Intrinsic;
   begin
      LED_Manager.Set_Color ((1 => HIL.Devices.GRN_LED));
      LED_Manager.LED_blink (LED_Manager.SLOW);

      NVRAM.Load (variable => NVRAM.VAR_BOOTCOUNTER, data => bootcounter);
      bootcounter := bootcounter + 1;
      Logger.Log (Logger.INFO, "Build Date: " & Compilation_Date & " " & Compilation_Time);
      Logger.Log (Logger.INFO, "Bootcount:  " & HIL.Byte'Image (bootcounter));
      NVRAM.Store (variable => NVRAM.VAR_BOOTCOUNTER, data => bootcounter);
      loop
         loop_time_start := Clock;

         --  LED heartbeat
         LED_Manager.LED_tick (MAIN_TICK_RATE_MS);
         LED_Manager.LED_sync;

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
