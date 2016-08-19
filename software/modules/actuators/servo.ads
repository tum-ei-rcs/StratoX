-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:    StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Servo Actuator

with Units; use Units;
with Config; use Config;

package Servo is

   type Servo_Type is (LEFT_ELEVON, RIGHT_ELEVON); 
   
   subtype Servo_Angle_Type is Angle_Type range CFG_SERVO_ANGLE_LIMIT_MIN .. CFG_SERVO_ANGLE_LIMIT_MAX;

   -- init
   procedure initialize;

   procedure activate;
  
   procedure deactivate;

   procedure set_Angle(servo: Servo_Type; angle : Servo_Angle_Type);
   
   -- function get_Angle(servo: Servo_Type) return Servo_Angle_Type;

   procedure sync;

end Servo;
