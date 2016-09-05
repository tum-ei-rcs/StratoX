--  Institution: Technische Universitaet Muenchen
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors:    Emanuel Regnath (emanuel.regnath@tum.de)
--              Martin Becker (becker@rcs.ei.tum.de)
--
--  @summary Servo Actuator frontend
with Units; use Units;
with Config; use Config;

package Servo with SPARK_Mode is

   type Servo_Type is (LEFT_ELEVON, RIGHT_ELEVON); 
   
   subtype Servo_Angle_Type is Angle_Type range CFG_SERVO_ANGLE_LIMIT_MIN .. CFG_SERVO_ANGLE_LIMIT_MAX;

   procedure initialize;

   procedure activate;
  
   procedure deactivate;
   
   procedure Set_Critical_Angle (which: Servo_Type; angle : Servo_Angle_Type);
   --  call this if the angle is vital at this very moment. It will be restored 
   --  immediately after a potential in-air reset. this procedure is a bit slower

   procedure Set_Angle (which: Servo_Type; angle : Servo_Angle_Type);
   --  call this for all other angles, which is faster.

   procedure sync;

end Servo;
