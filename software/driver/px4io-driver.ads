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
with units; use units;

package PX4IO.Driver is


	type Servo_Type is (LEFT_ELEVON, RIGHT_ELEVON); 
	subtype Servo_Angle_Type is units.Angle_Type;

	-- init
	procedure initialize;
        
        procedure read_Status;

	procedure set_Servo_Angle(servo : Servo_Type; angle : Servo_Angle_Type);


end PX4IO.Driver;
