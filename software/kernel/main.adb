-- Description:
-- Main System File
-- the main loop (TM)

with Ada.Real_Time;    use Ada.Real_Time;

with CPU;
with Units;            use Units;
--  with Units.Navigation; use Units.Navigation;

with HIL;

--  with MPU6000.Driver;
with PX4IO.Driver;
with ublox8.Driver;   use ublox8.Driver;
with NVRAM;
with Logger;
with Config.Software; use Config.Software;

with Mission;
with Console;
with Estimator;
with Controller;
with LED_Manager;
with Buzzer_Manager;
with Buildinfo;
with Profiler; use Profiler;

package body Main with SPARK_Mode => On is

   type LED_Counter_Type is mod 1000/Config.Software.MAIN_TICK_RATE_MS/2;
   G_led_counter : LED_Counter_Type := 0;


   procedure initialize is
      num_boots : HIL.Byte;
   begin
      CPU.initialize;

      --  start logger first
      declare
         ret : Logger.Init_Error_Code;
      begin
         Logger.Init (ret);
         pragma Unreferenced (ret);
      end;
      Logger.Set_Log_Level (CFG_LOGGER_LEVEL_UART);

      --perform_Self_Test;

      --MS5611.Driver.reset;
      -- MPU6000.Driver.Reset;

      -- wait to satisfy some (?) timing
      declare
         now : constant Time := Clock;
      begin
         delay until now + Milliseconds (50);
      end;

      --  start NVRAM (bootcounter...)
      Logger.log_console (Logger.INFO, "Initializing NVRAM...");
      NVRAM.Init;

      --  from now on, log everything to SDcard
      Logger.log_console (Logger.INFO, "Starting SDLog...");
      Logger.Start_SDLog; -- should be called after NVRAM.Init

      Buzzer_Manager.Initialize;
      Estimator.initialize;
      Controller.initialize;

      --  wait to satisfy some timing
      --  TODO XXX FIXME: why? This is too slow for in-air reset.
      declare
         now : constant Time := Clock;
      begin
         delay until now + Milliseconds (150); -- reduced from 1500 to 150
      end;

      --  Illustration how to use NVRAM
      declare
         exception_line : HIL.Byte_Array_2 := (0,0);
      begin
         NVRAM.Load (NVRAM.VAR_BOOTCOUNTER, num_boots); -- is maintained by the NVRAM itself
         declare
            strboot : constant String := HIL.Byte'Image (num_boots); -- unconstrained. Use in log_console => proof fail.
            pragma Assert (HIL.Byte'Size <= 8);
            pragma Assume (strboot'Length <= 4);
         begin
            Logger.log_console (Logger.INFO, ("Boot number: " & strboot));
            Logger.log_console (Logger.INFO, "Build date: " & Buildinfo.Compilation_ISO_Date
                                & " " & Buildinfo.Compilation_Time);
         end;
         NVRAM.Load (NVRAM.VAR_EXCEPTION_LINE_L, exception_line(1));
         NVRAM.Load (NVRAM.VAR_EXCEPTION_LINE_H, exception_line(2));
         Logger.log_console(Logger.WARN, "Last Exception: " & Integer'Image( Integer( HIL.toUnsigned_16( exception_line ) ) ) );
      end;

      -- TODO: pick up last mission state from NVRAM and continue where
      -- we left (that happens in case of loss of power)

   end initialize;

   procedure perform_Self_Test (passed : out Boolean) is
   begin
      LED_Manager.LED_switchOn;

      Logger.log_console (Logger.INFO, "Starting Self Test");

      Logger.log_console (Logger.DEBUG, "Logger: Debug Test Message");
      Logger.log_console (Logger.TRACE, "Logger: Trace Test Message");

      --  check NVRAM
      NVRAM.Self_Check (passed);
      if not passed then
         Logger.log_console (Logger.ERROR, "NVRAM self-check failed");
         return;
      else
         Logger.log_console (Logger.INFO, "NVRAM self-check passed");
      end if;

      --  check GPS
      declare
         Status : ublox8.Driver.Error_Type;
      begin
         ublox8.Driver.perform_Self_Check (Status);
         passed := Status = ublox8.Driver.SUCCESS;
      end;
      if not passed then
         Logger.log_console (Logger.ERROR, "Ublox8 self-check failed");
         return;
      else
         Logger.log_console (Logger.INFO, "Ublox8 self-check passed");
      end if;

   end perform_Self_Test;

   procedure run_Loop is
      msg     : constant String                      := "Main";

      loop_time_start   : Time      := Clock;
      loop_duration_max : Time_Span := Milliseconds (0);

      Main_Profile : Profile_Tag;

      --  body_info : Body_Type;

      command : Console.User_Command_Type;
      checks_passed : Boolean := False;
   begin
      Main_Profile.init(name => "Main");
      LED_Manager.LED_blink (LED_Manager.SLOW);

      Logger.log_console (Logger.INFO, msg);
      Mission.load_Mission;

      -- beep ever 10 seconds for one second at 1kHz.
      --Buzzer_Manager.Set_Freq (1000.0 * Hertz);
      --Buzzer_Manager.Set_Timing (period => 10.0 * Second, length => 1.0 * Second);
      --Buzzer_Manager.Set_Song( "The Final Countdown" );
      --Buzzer_Manager.Enable;

      -- arm PX4IO
      Controller.activate;

      loop
         loop_time_start := Clock;
         Main_Profile.start;


         -- LED alive
         --LED_Manager.LED_tick (MAIN_TICK_RATE_MS);
         G_led_counter := LED_Counter_Type'Succ( G_led_counter );
         if G_led_counter < LED_Counter_Type'Last/2 then
            LED_Manager.LED_switchOn;
         else
            LED_Manager.LED_switchOff;
         end if;


         -- Mission
         Mission.run_Mission;

         -- Estimator
--           Estimator.update;
--  --
--           body_info.orientation := Estimator.get_Orientation;
--           body_info.position := Estimator.get_Position;
--  --
--  --
--           -- Controller
--           Controller.set_Current_Orientation (body_info.orientation);
--           Controller.set_Current_Position (body_info.position);
--           Controller.runOneCycle;


         -- Console
         Console.read_Command( command );

         case ( command ) is
            when Console.TEST =>
               perform_Self_Test (checks_passed);
               if not checks_passed then
                  Logger.log_console (Logger.ERROR, "Self-checks failed");
               else
                  Logger.log_console (Logger.INFO, "Self-checks passed");
               end if;

            when Console.STATUS =>
               Estimator.log_Info;
               Controller.log_Info;
               PX4IO.Driver.read_Status;

               Logger.log_console (Logger.INFO, "Profile: " & Integer'Image ( Integer(
                                   Float( Units.To_Time(loop_duration_max) ) * 1000.0 ) ) & " ms" );

            when Console.ARM => Controller.activate;

            when Console.DISARM => Controller.deactivate;

            when Console.PROFILE =>
               Logger.log_console (Logger.INFO, "Profile: " & Integer'Image ( Integer(
                                   Float( Units.To_Time(loop_duration_max) ) * 1000.0 ) ) & " ms" );
               Main_Profile.log;

            when others =>
               null;
         end case;

         -- Profile
         Main_Profile.stop;
         declare
            now  : constant Time := Clock;
            diff : constant Time_Span := now - loop_time_start;
         begin
            if loop_duration_max < diff then
               loop_duration_max := diff;
            end if;
         end;

         -- wait remaining loop time
         delay until loop_time_start + Milliseconds (MAIN_TICK_RATE_MS);
      end loop;

   end run_Loop;



end Main;
