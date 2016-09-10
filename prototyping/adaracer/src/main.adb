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
--with Buzzer_Manager;
--with SDLog;
with ULog;

package body Main is

   ENDL : constant String := (Character'Val (13), Character'Val (10));

   procedure Initialize is
      success : Boolean := False;
      t_next  : Ada.Real_Time.Time;
      logret  : Logger.Init_Error_Code;
   begin
      CPU.initialize;

      Logger.init (logret);
      Logger.log_console (Logger.INFO, "---------------");
      Logger.log_console (Logger.INFO, "CPU initialized");

      --Buzzer_Manager.Initialize;

      LED_Manager.LED_switchOff;
      LED_Manager.Set_Color ((HIL.Devices.RED_LED => True, HIL.Devices.GRN_LED => False, HIL.Devices.BLU_LED => False));
      LED_Manager.LED_switchOn;



      Logger.log_console (Logger.INFO, "Initializing NVRAM...");
      NVRAM.Init;

      Logger.log_console (Logger.INFO, "Start SD Logging...");
      --Logger.Start_SDLog;

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

      LED_Manager.Set_Color ((HIL.Devices.RED_LED => True, HIL.Devices.GRN_LED => True, HIL.Devices.BLU_LED => False));
      LED_Manager.LED_switchOn;
      --  SDLog.Perf_Test (10);
      Logger.log_console (Logger.INFO, "SD Card check done");
   end Initialize;


   procedure Run_Loop is
      loop_time_start   : Time      := Clock;

      type prescaler is mod 100;
      p : prescaler := 0;

      type prescaler_gps is mod 20;
      pg : prescaler_gps := 0;
   begin
      LED_Manager.Set_Color ((HIL.Devices.RED_LED => False, HIL.Devices.GRN_LED => True, HIL.Devices.BLU_LED => False));
      LED_Manager.LED_blink (LED_Manager.SLOW);

      loop
         loop_time_start := Clock;

         --  LED heartbeat
         LED_Manager.LED_tick (MAIN_TICK_RATE_MS);
         LED_Manager.LED_sync;

         --  wait remaining loop time
         delay until loop_time_start + Milliseconds (MAIN_TICK_RATE_MS);
      end loop;
   end Run_Loop;

end Main;
