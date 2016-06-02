-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Estimator
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Estimates state data like orientation and velocity
-- 
-- ToDo:
-- [ ] Implementation


with Units; use Units;
with IMU;

package Estimator is


   IMU_Data : IMU.Sensor.Sample_Type;

	subtype Roll_Type is Units.Angle_Type range -180.0 .. 180.0;
	subtype Pitch_Type is Units.Angle_Type range -180.0 .. 180.0;
	subtype Yaw_Type is Units.Angle_Type range -180.0 .. 180.0;

	subtype Altitute_Type is Units.Length_Type range -10.0 .. 10_000.0;


	type Orientation_Type is record
		Roll : Integer;
		Pitch : Integer;
		Yaw : Integer;
	end record;

	type GPS_Loacation_Type is record
		Longitude : Float;
		Latitude : Float;
		Altitute : Altitute_Type;
	end record;

   

	-- init
	procedure initialize;

	-- fetch fresh measurement data
	procedure update;


end Estimator;
