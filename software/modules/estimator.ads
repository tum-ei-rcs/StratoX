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
with Units.Vectors; use Units.Vectors;
--with Dynamics3D;

package Estimator with SPARK_Mode is

   subtype Roll_Type is Units.Angle_Type range -180.0 .. 180.0;
   subtype Pitch_Type is Units.Angle_Type range -180.0 .. 180.0;
   subtype Yaw_Type is Units.Angle_Type range -180.0 .. 180.0;

   subtype Wind_Speed is
     Units.Linear_Velocity_Type range 0.0 .. 50.0; -- 180 km/h

   type Longitude_Type is new Units.Angle_Type range -180.0 .. 180.0;
   type Latitude_Type is new Units.Angle_Type range -90.0 .. 90.0;
   type Altitute_Type is new Units.Length_Type range -10.0 .. 10_000.0;

   type Orientation_Type is record
      Roll  : Roll_Type;
      Pitch : Pitch_Type;
      Yaw   : Yaw_Type;
   end record;

   type GPS_Loacation_Type is record
      Longitude : Longitude_Type;
      Latitude  : Latitude_Type;
      Altitute  : Altitute_Type;
   end record;
   
   
   
   function Orientation
     (gravity_vector : Linear_Acceleration_Vector) return Orientation_Type;

   -- init
   procedure initialize;

   -- fetch fresh measurement data
   procedure update;

private
   Object_Orientation : Orientation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
--     Object_Pose : Dynamics3D.Pose_Type := (
--        position => (0.0, 0.0, 0.0),
--        orientation => (others => 0.0) );
   

end Estimator;
