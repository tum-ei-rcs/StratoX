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

with Units; use Units;

generic
   type PID_Data_Type   is new Unit_Type;
   type PID_Output_Type is new Unit_Type;
   type PID_Coefficient_Type is new Unit_Type;
   PID_INTEGRAL_LIMIT_LOW  : PID_Data_Type;
   PID_INTEGRAL_LIMIT_HIGH : PID_Data_Type;
   PID_OUTPUT_LIMIT_LOW : PID_Output_Type := PID_Output_Type'First;
   PID_OUTPUT_LIMIT_HIGH : PID_Output_Type := PID_Output_Type'Last;   
package Generic_PID_Controller
   with SPARK_Mode
is

   type Pid_Object is private;
   subtype PID_Integral_Type is PID_Data_Type range PID_INTEGRAL_LIMIT_LOW.. PID_INTEGRAL_LIMIT_HIGH;
       

   procedure test(a : PID_Data_Type; b : in out PID_Data_Type);

   -- init
   procedure initialize(Pid : out Pid_Object; 
                        Kp  : PID_Coefficient_Type; 
                        Ki : PID_Coefficient_Type; 
                        Kd : PID_Coefficient_Type;
                        I_Limit_Low  : PID_Data_Type := PID_INTEGRAL_LIMIT_LOW;
                        I_Limit_High : PID_Data_Type := PID_INTEGRAL_LIMIT_HIGH;
                        Output_Limit_Low  : PID_Output_Type := PID_OUTPUT_LIMIT_LOW;
                        Output_Limit_High : PID_Output_Type := PID_OUTPUT_LIMIT_HIGH);

   procedure reset (Pid : out Pid_Object);

   function step(Pid : in out Pid_Object; error : PID_Data_Type; dt : Time_Type) return PID_Output_Type;

private


   type Pid_Object is record
      Previous_Error : PID_Data_Type;       --  Previous Error
      Integral     : PID_Integral_Type;     --  Integral
      Kp           : PID_Coefficient_Type;       --  Proportional Gain
      Ki           : PID_Coefficient_Type;       --  Integral Gain
      Kd           : PID_Coefficient_Type;       --  Derivative Gain
      I_Limit_Low  : PID_Data_Type;     --  Limit of integral term
      I_Limit_High : PID_Data_Type;     --  Limit of integral term
      Output_Limit_Low  : PID_Output_Type;
      Output_Limit_High : PID_Output_Type;
   end record;

end Generic_PID_Controller;
