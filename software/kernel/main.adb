-- Description:
-- Main System File
-- todo: better unit name

with CPU;
with Units;           use Units;
with Ada.Real_Time;   use Ada.Real_Time;
with led_manager;
with MS5611.Driver;
with PX4IO.Driver;
with MPU6000.Driver;
with HIL.UART;
with HIL.SPI;
with Logger;
with Config.Software; use Config.Software;
with Estimator;

with Interfaces; use Interfaces;

package body Main is

--      -- the mission can only go forward
--      type Mission_State_Type is (
--              UNKNOWN,
--              INITIALIZING,
--              SELF_TESTING,
--              READY_TO_START,
--              ASCENDING,
--              HOLDING,
--              DESCENDING,
--              LANDED,
--              FOUND,
--              EVALUATING
--      );
--
--
--      type Mission_Event_Type is (
--              UNKNOWN,
--              INITIALIZATION_START,
--              INITIALIZATION_END,
--              SELF_TEST_START,
--              SELF_TEST_END,
--              ARMED,
--              RELEASED,
--              BALLOON_CUT,
--              DESCENDING,
--              LANDED,
--              FOUND,
--              EVALUATED
--      );
--
--
--      type Health_Status_Type is (
--              UNKNOWN,
--              OK,
--              EMERGENCY
--      );
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
      result : Boolean := False;
      
      
      A, B, C, D, E, F : Integer_16 := 0;
   begin
      CPU.initialize;

      Logger.set_Log_Level (CFG_LOGGER_LEVEL_UART);
      --perform_Self_Test;

      --MS5611.Driver.reset;
      MPU6000.Driver.Reset;

      -- wait to satisfy some timing
      delay until Clock + Milliseconds (50);
      
      --MS5611.Driver.init;
      
      PX4IO.Driver.initialize;
      
      
      MPU6000.Driver.Init;
      result := MPU6000.Driver.Test_Connection;
      result := MPU6000.Driver.Self_Test;
      MPU6000.Driver.Get_Motion_6(A, B, C, D, E, F);
      
      
      
      
   end initialize;

   procedure perform_Self_Test is
   begin
      Logger.log (Logger.INFO, "Starting Self Test");

      Logger.log (Logger.DEBUG, "Logger: Debug Test Message");
      Logger.log (Logger.TRACE, "Logger: Trace Test Message");

   end perform_Self_Test;

   procedure run_Loop is
      data    : HIL.SPI.Data_Type (1 .. 3)  := (others => 0);
      data_rx : HIL.UART.Data_Type (1 .. 1) := (others => 0);
      msg     : String                      := "Main";

      loop_time_start   : Time      := Clock;
      loop_duration_max : Time_Span := Milliseconds (0);
   begin
      led_manager.LED_blink (led_manager.SLOW);

      Logger.log (Logger.INFO, msg);

      -- arm PX4IO
      --PX4IO.Driver.arm;

      loop
         loop_time_start := Clock;

         led_manager.LED_tick (MAIN_TICK_RATE_MS);
         led_manager.LED_sync;

         -- UART Test
         --HIL.UART.write(HIL.UART.Console, (70, 65) );
         HIL.UART.read (HIL.UART.Console, data_rx);

         case (Character'Val (data_rx (1))) is
            when '1' =>
               PX4IO.Driver.set_Servo_Angle
                 (PX4IO.Driver.LEFT_ELEVON,
                  20.0 * Degree);
            when '2' =>
               PX4IO.Driver.set_Servo_Angle
                 (PX4IO.Driver.LEFT_ELEVON,
                  90.0 * Degree);
            when '3' =>
               PX4IO.Driver.set_Servo_Angle
                 (PX4IO.Driver.LEFT_ELEVON,
                  180.0 * Degree);
            when '8' =>
               PX4IO.Driver.set_Servo_Angle
                 (PX4IO.Driver.RIGHT_ELEVON,
                  0.0 * Degree); -- Warning: value not in range of type "Servo_Angle_Type" defined at px4io-driver.ads:29
            when '9' =>
               PX4IO.Driver.set_Servo_Angle
                 (PX4IO.Driver.RIGHT_ELEVON,
                  90.0 * Degree);
            when '0' =>
               PX4IO.Driver.set_Servo_Angle
                 (PX4IO.Driver.RIGHT_ELEVON,
                  180.0 * Degree);

            when 't' =>
               perform_Self_Test;
            when 's' =>
               PX4IO.Driver.read_Status;
            when 'l' =>
               led_manager.LED_blink (led_manager.FAST);
            when 'd' =>
               PX4IO.Driver.disarm;
            when 'p' =>
               Logger.log
                 (Logger.INFO,
                  Integer'Image (loop_duration_max / Time_Span_Unit));
            when others =>
               null;
         end case;

         -- PX4IO
         PX4IO.Driver.sync_Outputs;

         -- MS5611 Test
         --MS5611.Driver.update_val;

         -- SPI Test
         --HIL.SPI.select_Chip(HIL.SPI.Extern);
         --HIL.SPI.transfer(HIL.SPI.Extern, (166, 0, 0), data );
         --HIL.SPI.deselect_Chip(HIL.SPI.Extern);

         -- profile
         if loop_duration_max < (Clock - loop_time_start) then
            loop_duration_max := Clock - loop_time_start;
         end if;

         -- wait remaining loop time
         delay until loop_time_start + Milliseconds (MAIN_TICK_RATE_MS);
      end loop;
   end run_Loop;

end Main;
