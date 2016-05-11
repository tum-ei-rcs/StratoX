
package body PX4IO.Driver is


	subtype Servo_Number_Type is range 1 .. 2; 
	subtype Servo_Angle_Type is new units.Degree_Type;

	-- init
	procedure initialize is
	begin
		null;
	end initialize;

	procedure set_Servo_Angle(number : Servo_Number_Type; angle : Servo_Angle_Type) is
	begin
		null;
	end sleep;

end PX4IO.Driver;
