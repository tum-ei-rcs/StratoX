-- Description:
-- Main System File
-- todo: better unit name

with Ada.Real_Time;                     use Ada.Real_Time;

with CPU;
with Units;            use Units;
with Units.Navigation; use Units.Navigation;

with MPU6000.Driver;
with HIL;
with NVRAM;
with Logger;
with Config.Software; use Config.Software;

with Crash;
with Mission;
with Console;
with Estimator;
with Controller;
with LED_Manager;
with Buzzer_Manager;
with SDLog;
with Buildinfo;
with Profiler; use Profiler;
with Interfaces; use Interfaces;

package body Main is

   type LED_Counter_Type is mod 1000/Config.Software.MAIN_TICK_RATE_MS/2;
   G_led_counter : LED_Counter_Type := 0;


   procedure initialize is

      --        Test             : Float       := Sin (100.0);
      --        Foo              : Real_Vector := (10.0, 10.0, 10.0);
      --        A, B, C, D, E, F : Integer_16  := 0;
      num_boots : HIL.Byte;
   begin

--        Test := abs (Foo);

      CPU.initialize;

      Buzzer_Manager.Initialize;
      Logger.set_Log_Level (CFG_LOGGER_LEVEL_UART);
      --perform_Self_Test;

      --MS5611.Driver.reset;
      -- MPU6000.Driver.Reset;

      -- wait to satisfy some timing
      delay until Clock + Milliseconds (50);

      Logger.log (Logger.INFO, "Initializing SDLog...");
      SDLog.Init;

      Logger.log (Logger.INFO, "Initializing NVRAM...");
      NVRAM.Init;

      Estimator.initialize;
      Controller.initialize;

      -- wait to satisfy some timing
      delay until Clock + Milliseconds (1500);

      -- Illustration how to use NVRAM
      declare
         exception_line : HIL.Byte_Array_2;
      begin
         NVRAM.Load (NVRAM.VAR_BOOTCOUNTER, num_boots);
         if num_boots < HIL.Byte'Last then
            num_boots := num_boots + 1;
            NVRAM.Store (NVRAM.VAR_BOOTCOUNTER, num_boots);
         end if;
         Logger.log (Logger.INFO, "Boot number: " & HIL.Byte'Image (num_boots));

         NVRAM.Load (NVRAM.VAR_EXCEPTION_LINE_L, exception_line(1));
         NVRAM.Load (NVRAM.VAR_EXCEPTION_LINE_H, exception_line(2));
      end;

      --  Illustration of logging to SD card
      -- SDLog.List_Rootdir; -- that is nice to look at, but highly unsafe
      Logger.log (Logger.INFO, "Starting SDLog...");
      declare
         buildstring : constant String := Buildinfo.Short_Datetime;
         fname       : constant String := num_boots'Img & ".log";
         ENDL        : constant String := (Character'Val (13), Character'Val (10));
      begin
         if not SDLog.Start_Logfile (dirname => buildstring, filename => fname)
         then
            Logger.log (Logger.ERROR, "Cannot create logfile: " & buildstring & "/" & fname);
         else
            Logger.log (Logger.INFO, "Log name: " & buildstring & "/" & fname);
            SDLog.Write_Log ("Build Stamp: "
                                       & Buildinfo.Compilation_Date & " "
                                       & Buildinfo.Compilation_Time & ENDL);
            SDLog.Flush_Log; -- force to write to SD card right now (slow! Only do this in case of emergency!)
         end if;
      end;

      -- TODO: pick up last mission state from NVRAM and continue where
      -- we left (that happens in case of loss of power)

   end initialize;

   procedure perform_Self_Test is
      success : Boolean;

   begin
      LED_Manager.LED_switchOn;

      Logger.log (Logger.INFO, "Starting Self Test");

      Logger.log (Logger.DEBUG, "Logger: Debug Test Message");
      Logger.log (Logger.TRACE, "Logger: Trace Test Message");

      NVRAM.Self_Check (success);
      if not success then
         Logger.log (Logger.ERROR, "NVRAM self-check failed");
      else
         Logger.log (Logger.INFO, "NVRAM self-check passed");
      end if;

   end perform_Self_Test;

   procedure run_Loop is
      msg     : constant String                      := "Main";

      loop_time_start   : Time      := Clock;
      loop_duration_max : Time_Span := Milliseconds (0);

      Main_Profile : Profile_Tag;

      body_info : Body_Type;

      command : Console.User_Command_Type;
   begin
      Main_Profile.init(name => "Main");
      LED_Manager.LED_blink (LED_Manager.SLOW);

      Logger.log (Logger.INFO, msg);
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
            when Console.TEST => perform_Self_Test;

            when Console.STATUS =>
               Estimator.log_Info;
               Controller.log_Info;

               Logger.log (Logger.INFO, "Profile: " & Integer'Image ( Integer( Float( Units.To_Time(loop_duration_max) ) * 1000.0 ) ) & " ms" );

            when Console.ARM => Controller.activate;

            when Console.DISARM => Controller.deactivate;

            when Console.PROFILE =>
               Logger.log (Logger.INFO, "Profile: " & Integer'Image ( Integer( Float( Units.To_Time(loop_duration_max) ) * 1000.0 ) ) & " ms" );
               Main_Profile.log;

            when others =>
               null;
         end case;

         -- Profile
         Main_Profile.stop;
         if loop_duration_max < (Clock - loop_time_start) then
            loop_duration_max := Clock - loop_time_start;
         end if;

         -- wait remaining loop time
         delay until loop_time_start + Milliseconds (MAIN_TICK_RATE_MS);
      end loop;
   end run_Loop;

end Main;
