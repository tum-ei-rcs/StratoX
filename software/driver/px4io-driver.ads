-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      PX4IO Driver
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Driver for the PX4IO co-processor
-- 
-- ToDo:
-- [ ] Implementation

with HIL; use HIL;
with HIL.UART;
with units; use units;

package PX4IO.Driver 
with SPARK_Mode 
is

   SERVO_ANGLE_MIN_LIMIT : constant := 0.0;
   SERVO_ANGLE_MAX_LIMIT : constant := 180.0;
   
   MOTOR_SPEED_LIMIT_MIN : constant := 0.0;
   MOTOR_SPEED_LIMIT_MAX : constant := 360.0*10.0;  -- Degree per Second


   type Servo_Type is (LEFT_ELEVON, RIGHT_ELEVON); 
   subtype Servo_Angle_Type is units.Angle_Type range SERVO_ANGLE_MIN_LIMIT .. SERVO_ANGLE_MAX_LIMIT;
   
   subtype Motor_Speed_Type is Units.Angular_Velocity_Type range
       MOTOR_SPEED_LIMIT_MIN .. MOTOR_SPEED_LIMIT_MAX;
   

   -- init
   procedure initialize;
   
   procedure arm;
   
   procedure disarm;
   
   procedure read_Status;

   procedure set_Servo_Angle(servo : Servo_Type; angle : Servo_Angle_Type);

   procedure sync_Outputs;

private
   subtype Page_Type is HIL.Byte;
   subtype Offset_Type is HIL.Byte;
   
   subtype Data_Type is HIL.UART.Data_Type;
   
   function valid_Package( data : in Data_Type ) return Boolean;
   
   procedure write(page : Page_Type; offset : Offset_Type; data : Data_Type) 
   with pre => data'Length mod 2 = 0 and data'Length <= 64;

end PX4IO.Driver;
