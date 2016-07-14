-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Units
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Additional units for navigation
--

with Units.Vectors; use Units.Vectors;

package Units.Navigation with SPARK_Mode is


   -- Date
   subtype Month_Type is Integer range 1 .. 12;
   subtype Day_Of_Month_Type is Integer range 1 .. 31;
   subtype Year_Type is Integer;

   type Hour_Type is mod 24;
   type Minute_Type is mod 60;
   type Second_Type is mod 60;



   -- GPS Position
   subtype Longitude_Type is Units.Angle_Type range -180.0 * Degree .. 180.0 * Degree;
   subtype Latitude_Type is Units.Angle_Type range -90.0 * Degree .. 90.0 * Degree;
   subtype Altitude_Type is Units.Length_Type range -10.0 * Meter .. 10_000.0 * Meter;

   type GPS_Loacation_Type is record
      Longitude : Longitude_Type;
      Latitude  : Latitude_Type;
      Altitude  : Altitude_Type;
   end record;

   type Longitude_Array is array (Natural range <>) of Longitude_Type;
   type Latitude_Array is array (Natural range <>) of Latitude_Type;
   type Altitude_Array is array (Natural range <>) of Altitude_Type;

   type GPS_Fix_Type is (NO_FIX, FIX_2D, FIX_3D);


   -- Orientation
   subtype Roll_Type is Units.Angle_Type range -180.0 * Degree .. 180.0 * Degree;
   subtype Pitch_Type is Units.Angle_Type range -180.0 * Degree .. 180.0 * Degree; -- FIXME: -90 .. 90 ?
   subtype Yaw_Type is Units.Angle_Type range 0.0 * Degree .. 360.0 * Degree;

   type Orientation_Type is record
      Roll  : Roll_Type;
      Pitch : Pitch_Type;
      Yaw   : Yaw_Type;
   end record;


   -- Compass Heading
   -- Route: goal, track: real, course: direction of route, heading: pointing direction of the nose

   subtype Heading_Type is Angle_Type range 0.0 * Degree .. DEGREE_360;

   NORTH : constant Heading_Type :=   0.0 * Degree;
   EAST  : constant Heading_Type :=  90.0 * Degree;
   SOUTH : constant Heading_Type := 180.0 * Degree;
   WEST  : constant Heading_Type := 270.0 * Degree;


   type Body_Type is record
      mass        : Mass_Type;
      position    : GPS_Loacation_Type;
      orientation : Orientation_Type;
      linear_velocity  : Linear_Velocity_Vector;
      angular_velocity : Angular_Velocity_Vector;
   end record;


   function Heading(mag_vector : Magnetic_Flux_Density_Vector; orientation : Orientation_Type) return Heading_Type;




end Units.Navigation;
