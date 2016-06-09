-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Units
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Additional units for navigation
--


package Units.Navigation with SPARK_Mode is


   -- GPS
   subtype Longitude_Type is Units.Angle_Type range -180.0 .. 180.0;
   subtype Latitude_Type is Units.Angle_Type range -90.0 .. 90.0;
   subtype Altitude_Type is Units.Length_Type range -10.0 .. 10_000.0;

   type GPS_Loacation_Type is record
      Longitude : Longitude_Type;
      Latitude  : Latitude_Type;
      Altitude  : Altitude_Type;
   end record;


   -- Compass
   -- Route: goal, track: real, course: direction of route, heading: pointing direction of the nose

   subtype Heading_Type is Angle_Type range 0.0 .. DEGREE_360;

   NORTH : constant Heading_Type :=   0.0 * Degree;
   EAST  : constant Heading_Type :=  90.0 * Degree;
   SOUTH : constant Heading_Type := 180.0 * Degree;
   WEST  : constant Heading_Type := 270.0 * Degree;

end Units.Navigation;
