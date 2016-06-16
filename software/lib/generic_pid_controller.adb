
package body Generic_PID_Controller is


   procedure initialize( pid : out Pid_Object; 
                         Kp  : in  PID_Coefficient_Type; 
                         Ki  : in  PID_Coefficient_Type; 
                         Kd  : in  PID_Coefficient_Type ) 
   is
   begin
      Pid.Previous_Error := PID_Data_Type( 0.0 );
      Pid.Integral := PID_Data_Type( 0.0 );
      Pid.Kp := Kp;
      Pid.Ki := Ki;
      Pid.Kd := Kd;
   end initialize;


   procedure reset (pid : out Pid_Object) is
   begin
      Pid.Previous_Error := PID_Data_Type( 0.0 );
      Pid.Integral := PID_Data_Type( 0.0 );
   end reset;


   -- step
   function step ( pid   : in out Pid_Object; 
                   error : PID_Data_Type; 
                   dt    : Time_Type )
                  return PID_Output_Type 
   is
      derivate     : PID_Data_Type := PID_Data_Type( 0.0 );
      proportional : PID_Data_Type := PID_Data_Type( 0.0 );
      output       : PID_Output_Type := PID_Output_Type( 0.0 );
   begin
      Pid.Integral := PID_Data_Type( Unit_Type(Pid.Integral) + Unit_Type(error) * Unit_Type(dt) ); -- todo: saturation (exception?, operator overload)
      
      derivate := PID_Data_Type( Unit_Type(error - Pid.Previous_Error) / dt );
      Pid.Previous_Error := error;
      
      
      output := PID_Output_Type( Unit_Type( Pid.Kp ) * Unit_Type( error ) +
                                 Unit_Type( Pid.Ki ) * Unit_Type( Pid.Integral ) +
                                 Unit_Type( Pid.Kd ) * Unit_Type( derivate ) );
      
      if output < PID_Output_Type( -0.7 ) then
         output := PID_Output_Type( -0.7 );
      elsif output > PID_Output_Type( 0.7 ) then
         output := PID_Output_Type( 0.7 );
      end if;

      return output;
   end step;

end Generic_PID_Controller;
