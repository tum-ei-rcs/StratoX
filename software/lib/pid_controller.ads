-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
-- Module: PID controller
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: PID Controller based on the Ada firmware for crazyflie
--              See https://github.com/AnthonyLeonardoGracio/crazyflie-firmware
-- 
-- ToDo:
-- [ ] Implementation

with units; use units;

generic
   type PID_Data_Type is new Unit_Type;
   type PID_Time_Type is new Unit_Type;
   type PID_Coefficient_Type is private;
   PID_INTEGRAL_LIMIT_LOW  : PID_Data_Type;
   PID_INTEGRAL_LIMIT_HIGH : PID_Data_Type;
package PID_Controller
--with SPARK_Mode
is

    type Pid_Object is private;
    subtype PID_Integral_Type is PID_Data_Type range PID_INTEGRAL_LIMIT_LOW.. PID_INTEGRAL_LIMIT_HIGH;
       

	-- init
	procedure initialize(pid : out Pid_Object; Kp : PID_Coefficient_Type; Ki : PID_Coefficient_Type; Kd : PID_Coefficient_Type);

	function step(pid : in out Pid_Object; error : PID_Data_Type; dt : PID_Time_Type) return PID_Data_Type;

private


   type Pid_Object is record
      Previous_Error : PID_Data_Type;       --  Previous Error
      Integral     : PID_Integral_Type;     --  Integral
      Kp           : PID_Coefficient_Type;       --  Proportional Gain
      Ki           : PID_Coefficient_Type;       --  Integral Gain
      Kd           : PID_Coefficient_Type;       --  Derivative Gain
      I_Limit_Low  : PID_Data_Type;     --  Limit of integral term
      I_Limit_High : PID_Data_Type;     --  Limit of integral term
   end record;

end PID_Controller;
