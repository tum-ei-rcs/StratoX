-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
-- Module: Controller
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Controls all actuators, calls PID loop
-- 
-- ToDo:
-- [ ] Implementation

with units;

package Controller is

   type System_Data_Type is new Integer;

	type GPS_Loacation_Type is record
		Longitude : Integer;
		Latitude : Integer;
		Altitute : Integer;
	end record;

	type Direction_Type is new Integer; -- Degree_Type, north is 0°
	type Tilt_Type is new Integer; -- Degree_Type, 

	-- init
	procedure initialize;

	procedure setTarget(location : GPS_Loacation_Type);

	procedure runOneCycle(systemData : System_Data_Type);

-- private
--  	procedure controlDirection(directionError : Direction_Type);
--  
--  	procedure controlTilt(tiltError : Tilt_Type);


end Controller;
