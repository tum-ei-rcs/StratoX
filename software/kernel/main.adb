-- Description:
-- Main System File
-- todo: better unit name

with Ada.Real_Time;                     use Ada.Real_Time;

with CPU;
with Units;            use Units;
with Units.Navigation; use Units.Navigation;

with MPU6000.Driver;
with HIL.UART;
with HIL.SPI;
with NVRAM;
with Logger;
with Config.Software; use Config.Software;

with HIL.Devices;

with Estimator;
with Controller;
with LED_Manager;

with Interfaces; use Interfaces;

package body Main is

   type Health_Status_Type is (UNKNOWN, OK, EMERGENCY);
--
--      type Altitude_State_Type is (
--              GROUND,
--              ASCENDING,
--              STABLE,
--              DESCENDING,
--              FREEFALL
--      );
--
--
--      type System_State_Type is record
--              Mission_State : Mission_State_Type := UNKNOWN;
--              Health_Status : Health_Status_Type := UNKNOWN;
--      end record;

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
      data_rx : HIL.UART.Data_Type (1 .. 1) := (others => 0);
      msg     : constant String                      := "Main";

      loop_time_start   : Time      := Clock;
      loop_duration_max : Time_Span := Milliseconds (0);

      body_info : Body_Type;

   begin
      LED_Manager.LED_blink (LED_Manager.SLOW);

      Logger.log (Logger.INFO, msg);

      -- arm PX4IO
      Controller.activate;

      loop
         loop_time_start := Clock;

         -- LED alive
         LED_Manager.LED_tick (MAIN_TICK_RATE_MS);
         LED_Manager.LED_sync;

         -- UART Test
         --HIL.UART.write(HIL.UART.Console, (70, 65) );
         HIL.UART.read (HIL.Devices.CONSOLE, data_rx);

         case (Character'Val (data_rx (1))) is
--              when '1' =>
--                 PX4IO.Driver.set_Servo_Angle
--                   (PX4IO.Driver.LEFT_ELEVON,
--                    20.0 * Degree);
--              when '2' =>
--                 PX4IO.Driver.set_Servo_Angle
--                   (PX4IO.Driver.LEFT_ELEVON,
--                    90.0 * Degree);
--              when '3' =>
--                 PX4IO.Driver.set_Servo_Angle
--                   (PX4IO.Driver.LEFT_ELEVON,
--                    180.0 * Degree);
--              when '8' =>
--                 PX4IO.Driver.set_Servo_Angle
--                   (PX4IO.Driver.RIGHT_ELEVON,
--                    0.0 *
--                    Degree); -- Warning: value not in range of type "Servo_Angle_Type" defined at px4io-driver.ads:29
--              when '9' =>
--                 PX4IO.Driver.set_Servo_Angle
--                   (PX4IO.Driver.RIGHT_ELEVON,
--                    90.0 * Degree);
--              when '0' =>
--                 PX4IO.Driver.set_Servo_Angle
--                   (PX4IO.Driver.RIGHT_ELEVON,
--                    180.0 * Degree);

            when 't' =>
               perform_Self_Test;

            when 's' =>
               null;
               --PX4IO.Driver.read_Status;

            when 'r' =>
               Logger.log
                 (Logger.INFO,
                  "RPY: " &
                  AImage (body_info.orientation.Roll) &
                  ", " &
                  AImage (body_info.orientation.Pitch) &
                  ", " &
                  AImage (body_info.orientation.Yaw));

            when 'l' =>
               LED_Manager.LED_blink (LED_Manager.FAST);

            when 'd' =>
               null;
               --PX4IO.Driver.disarm;

            when 'p' =>
               Logger.log (Logger.INFO, Integer'Image (loop_duration_max / Time_Span_Unit));

            when others =>
               null;
         end case;

         -- Estimator
         Estimator.update;

         body_info.orientation := Estimator.get_Orientation;

         -- Controller
         Controller.set_Current_Orientation (body_info.orientation);
         Controller.runOneCycle;


         -- profile
         if loop_duration_max < (Clock - loop_time_start) then
            loop_duration_max := Clock - loop_time_start;
         end if;

         -- TODO: write mission state to NVRAM, if it has changed.

         -- wait remaining loop time
         delay until loop_time_start + Milliseconds (MAIN_TICK_RATE_MS);
      end loop;
   end run_Loop;

end Main;
