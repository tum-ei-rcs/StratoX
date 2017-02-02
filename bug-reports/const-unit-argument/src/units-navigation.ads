-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Units
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Additional units for navigation
--

--with Units.Vectors; use Units.Vectors;
with Units.Numerics; use Units.Numerics;
with Interfaces;

pragma Elaborate_All(Units.Numerics);

package Units.Navigation with SPARK_Mode is

   -- GPS Position
   subtype Longitude_Type is Units.Angle_Type range -180.0 * Degree .. 180.0 * Degree;
   subtype Latitude_Type is Units.Angle_Type range -90.0 * Degree .. 90.0 * Degree;
   subtype Altitude_Type is Units.Length_Type range -10_000.0 * Meter .. 40_000.0 * Meter;

   type GPS_Loc_Type is record
      Longitude : Longitude_Type := 0.0 * Degree;
      Latitude  : Latitude_Type := 0.0 * Degree;
      Altitude  : Altitude_Type := 0.0 * Meter;
   end record;

   -- Compass Heading
   -- Route: goal, track: real, course: direction of route, heading: pointing direction of the nose

   subtype Heading_Type is Angle_Type range 0.0 * Degree .. DEGREE_360;

   EARTH_RADIUS : constant Length_Type := 6378.137 * Kilo * Meter;
   METER_PER_LAT_DEGREE : constant Length_Angle_Ratio_Type := 111.111 * Kilo * Meter / Degree; -- average lat


   function Distance (source : GPS_Loc_Type; target: GPS_Loc_Type) return Length_Type;
   --  compute great-circle distance between to Lat/Lon

   function Bearing (source_location : GPS_Loc_Type; target_location  : GPS_Loc_Type) return Heading_Type
     with Post => Bearing'Result in 0.0 * Degree .. 360.0 * Degree;
   --  compute course (initial bearing, forward azimuth) from source to target location


end Units.Navigation;
