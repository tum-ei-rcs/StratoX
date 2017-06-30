
package body Generic_PID_Controller with SPARK_Mode => On is


   procedure initialize( Pid : out Pid_Object; 
                         Kp  : PID_Coefficient_Type; 
                         Ki  : PID_Coefficient_Type; 
                         Kd  : PID_Coefficient_Type;
                         I_Limit_Low  : PID_Data_Type := PID_INTEGRAL_LIMIT_LOW;
                         I_Limit_High : PID_Data_Type := PID_INTEGRAL_LIMIT_HIGH;
                         Output_Limit_Low  : PID_Output_Type := PID_OUTPUT_LIMIT_LOW;
                         Output_Limit_High : PID_Output_Type := PID_OUTPUT_LIMIT_HIGH ) 
   is
   begin
      Pid.Previous_Error := PID_Data_Type( 0.0 );
      Pid.Integral := PID_Data_Type( 0.0 );
      Pid.Kp := Kp;
      Pid.Ki := Ki;
      Pid.Kd := Kd;
      Pid.I_Limit_Low := I_Limit_Low;
      Pid.I_Limit_High := I_Limit_High;
      Pid.Output_Limit_Low := Output_Limit_Low;
      Pid.Output_Limit_High := Output_Limit_High;
   end initialize;



   procedure reset (Pid : out Pid_Object) is
   begin
      Pid.Previous_Error := PID_Data_Type( 0.0 );
      Pid.Integral := PID_Data_Type( 0.0 );
   end reset;


   -- step
   procedure step ( Pid   : in out Pid_Object; 
                    error : PID_Data_Type; 
                    dt    : Time_Type;
                    result : out PID_Output_Type) 
   is
      derivate     : Base_Unit_Type := 0.0;
      output       : Base_Unit_Type := 0.0;
      tmp_integral : Base_Unit_Type := 0.0;
   begin
   
      -- Intetgral Part
      tmp_integral := Base_Unit_Type(Pid.Integral) + Base_Unit_Type(error) * Base_Unit_Type(dt);
      if tmp_integral in  Base_Unit_Type(Pid.I_Limit_Low) .. Base_Unit_Type(Pid.I_Limit_High) then
         Pid.Integral := PID_Integral_Type( tmp_integral );
      else
         if tmp_integral <  Base_Unit_Type(Pid.I_Limit_Low) then
            Pid.Integral := Pid.I_Limit_Low;
         else 
            Pid.Integral := Pid.I_Limit_High;
         end if;       
      end if;   

      -- Derivate Part
      derivate := Base_Unit_Type(error - Pid.Previous_Error) / Base_Unit_Type( dt );
      Pid.Previous_Error := error;
      
      
      -- Calculate Output with Gains
      output := Base_Unit_Type( Pid.Kp ) * Base_Unit_Type( error ) +
                Base_Unit_Type( Pid.Ki ) * Base_Unit_Type( Pid.Integral ) +
                Base_Unit_Type( Pid.Kd ) * derivate;
      
      
      -- Saturate Output
      if output < Base_Unit_Type( Pid.Output_Limit_Low ) then
         output := Base_Unit_Type( Pid.Output_Limit_Low );
      elsif output > Base_Unit_Type(Pid.Output_Limit_High) then
         output := Base_Unit_Type( Pid.Output_Limit_High );
      end if;

      result := PID_Output_Type( output );
   end step;

end Generic_PID_Controller;
