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



with Mission;
with Console;
with Estimator;
with Controller;
with LED_Manager;

with Interfaces; use Interfaces;

package body Main is



   procedure initialize is

      --        Test             : Float       := Sin (100.0);
      --        Foo              : Real_Vector := (10.0, 10.0, 10.0);
      --        A, B, C, D, E, F : Integer_16  := 0;

   begin

--        Test := abs (Foo);

      CPU.initialize;

      Logger.set_Log_Level (CFG_LOGGER_LEVEL_UART);
      --perform_Self_Test;

      --MS5611.Driver.reset;
      MPU6000.Driver.Reset;

      NVRAM.Init;

      -- wait to satisfy some timing
      delay until Clock + Milliseconds (50);

      --PX4IO.Driver.initialize;

      Estimator.initialize;
      Controller.initialize;

         -- Illustration how to use NVRAM

      declare
         num_boots : HIL.Byte;

      begin
         NVRAM.Load (NVRAM.VAR_BOOTCOUNTER, num_boots);
         if num_boots < HIL.Byte'Last then
            num_boots := num_boots + 1;
            NVRAM.Store (NVRAM.VAR_BOOTCOUNTER, num_boots);
         end if;
         Logger.log (Logger.INFO, "Boot number: " & HIL.Byte'Image (num_boots));
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

      body_info : Body_Type;

      command : Console.User_Command_Type;
   begin
      LED_Manager.LED_blink (LED_Manager.SLOW);

      Logger.log (Logger.INFO, msg);
      Mission.start_New_Mission;


      -- arm PX4IO
      Controller.activate;

      loop
         loop_time_start := Clock;

         -- LED alive
         LED_Manager.LED_tick (MAIN_TICK_RATE_MS);
         LED_Manager.LED_sync;


         -- Estimator
         Estimator.update;

         body_info.orientation := Estimator.get_Orientation;
         body_info.position := Estimator.get_Position;


         -- Controller
         Controller.set_Current_Orientation (body_info.orientation);
         Controller.runOneCycle;


         -- Console
         Console.read_Command( command );

         case ( command ) is
            when Console.TEST => perform_Self_Test;

            when Console.STATUS =>
               Logger.log( Logger.INFO, "RPY: " &
                  AImage (body_info.orientation.Roll) & ", " &
                  AImage (body_info.orientation.Pitch) & ", " &
                  AImage (body_info.orientation.Yaw));

               Logger.log( Logger.INFO, "GPS: long: " &
                  AImage (body_info.position.Longitude) & ", lat: " &
                  AImage (body_info.position.Latitude) & ", alt: " &
                  Integer'Image ( Integer( body_info.position.Altitude ) ));

            when Console.ARM => Controller.activate;

            when Console.DISARM => Controller.deactivate;

            when Console.PROFILE =>
               Logger.log (Logger.INFO, Integer'Image (loop_duration_max / Time_Span_Unit));

            when others =>
               null;
         end case;


         -- Profile
         if loop_duration_max < (Clock - loop_time_start) then
            loop_duration_max := Clock - loop_time_start;
         end if;

         -- TODO: write mission state to NVRAM, if it has changed.

         -- wait remaining loop time
         delay until loop_time_start + Milliseconds (MAIN_TICK_RATE_MS);
      end loop;
   end run_Loop;

end Main;
