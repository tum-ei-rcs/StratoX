-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:    StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Servo Actuator

with Units; use Units;

package Servo is

   type Servo_Type is (LEFT_ELEVON, RIGHT_ELEVON); 

   -- init
   procedure initialize;

   procedure activate;
  
   procedure deactivate;

   procedure set_Angle(servo: Servo_Type; angle : Angle_Type);

   procedure sync;

end Servo;
