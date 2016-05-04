
package body PID_Controller is


	procedure initialize(
		pid : out Pid_Object; 
		Kp  : in  PID_Coefficient_Type; 
		Ki  : in  PID_Coefficient_Type; 
		Kd  : in  PID_Coefficient_Type ) 
	is
	begin
      Pid.Previous_Error := PID_Data_Type'First;
      Pid.Integral := PID_Data_Type'First;
      Pid.Kp := Kp;
      Pid.Ki := Ki;
      Pid.Kd := Kd;
	end initialize;


	-- step
	function step(
		pid : in out Pid_Object; 
		error : PID_Data_Type; 
		dt : PID_Time_Type) 
	return PID_Data_Type 
	is
		derivate : PID_Data_Type := 0;
		proportional : PID_Data_Type := 0;
		output : PID_Data_Type := 0;
	begin
		Pid.Integral := Pid.Integ + error * dt; -- todo: saturation (exception?, operator overload)
		derivate := (error - Pid.Previous_Error) / dt;

		output := ( Pid.Kp * error +
			        Pid.Ki * Pid.Integral +
			        Pid.Kd * derivate );

		return output;
	end step;

end PID_Controller;
