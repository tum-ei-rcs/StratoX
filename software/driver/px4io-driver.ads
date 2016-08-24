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
with Units; use Units;
with Config; use Config;
with Interfaces; use Interfaces;

package PX4IO.Driver 
with SPARK_Mode
is

   
   MOTOR_SPEED_LIMIT_MIN : constant := CFG_MOTOR_SPEED_LIMIT_MIN;
   MOTOR_SPEED_LIMIT_MAX : constant := CFG_MOTOR_SPEED_LIMIT_MAX;

   SERVO_PULSE_LENGTH_LIMIT_MIN : constant := Unsigned_16 ( CFG_SERVO_PULSE_LENGTH_LIMIT_MIN / (1.0 * Micro * Second) ); -- Integer of Microseconds
   SERVO_PULSE_LENGTH_LIMIT_MAX : constant := Unsigned_16 ( CFG_SERVO_PULSE_LENGTH_LIMIT_MAX / (1.0 * Micro * Second) );

   G_Pulse : Unsigned_16 := SERVO_PULSE_LENGTH_LIMIT_MIN;

   type Servo_Type is (LEFT_ELEVON, RIGHT_ELEVON); 
   
   subtype Servo_Angle_Type is Units.Angle_Type range 
      CFG_SERVO_ANGLE_LIMIT_MIN .. CFG_SERVO_ANGLE_LIMIT_MAX;
   
   subtype Motor_Speed_Type is Units.Angular_Velocity_Type range
      MOTOR_SPEED_LIMIT_MIN .. MOTOR_SPEED_LIMIT_MAX;
   

   -- init
   procedure initialize;
   
   procedure Self_Check (result : out Boolean);
   
   procedure arm;
   
   procedure disarm;
   
   procedure read_Status;

   procedure set_Servo_Angle(servo : Servo_Type; angle : Servo_Angle_Type);

   procedure set_Motor_Speed( speed : Motor_Speed_Type );
   
   procedure sync_Outputs;

private
   subtype Page_Type is HIL.Byte;
   subtype Offset_Type is HIL.Byte;
   
   subtype Data_Type is HIL.UART.Data_Type;
   
   function valid_Package( data : in Data_Type ) return Boolean;
   
   procedure write(page : Page_Type; offset : Offset_Type; data : Data_Type; retries : Natural := 2) 
   with pre => data'Length mod 2 = 0 and data'Length <= 64;

end PX4IO.Driver;
