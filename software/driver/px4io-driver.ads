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
with units;

package PX4IO.Driver is


	subtype Servo_Number_Type is Integer range 1 .. 2; 
	subtype Servo_Angle_Type is units.Angle_Type;

	-- init
	procedure initialize;

	procedure set_Servo_Angle(number : Servo_Number_Type; angle : Servo_Angle_Type);


end PX4IO.Driver;
