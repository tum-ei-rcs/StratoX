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
with Units.Numerics; use Units.Numerics;

pragma Elaborate_All(Units.Numerics);

package Units.Navigation with SPARK_Mode is


   -- Date
   type Month_Type is range 1 .. 12 with Default_Value => 1;
   type Day_Of_Month_Type is range 1 .. 31 with Default_Value => 1;
   type Year_Type is new Integer with Default_Value => 1970;

   type Hour_Type is mod 24 with Default_Value => 0;
   type Minute_Type is mod 60 with Default_Value => 0;
   type Second_Type is mod 60 with Default_Value => 0;



   -- GPS Position
   subtype Longitude_Type is Units.Angle_Type range -180.0 * Degree .. 180.0 * Degree;
   subtype Latitude_Type is Units.Angle_Type range -90.0 * Degree .. 90.0 * Degree;
   subtype Altitude_Type is Units.Length_Type range -10_000.0 * Meter .. 10_000.0 * Meter;

   type GPS_Loacation_Type is record
      Longitude : Longitude_Type := 0.0 * Degree;
      Latitude  : Latitude_Type := 0.0 * Degree;
      Altitude  : Altitude_Type := 0.0 * Meter;
   end record;

   subtype GPS_Translation_Type is GPS_Loacation_Type;    -- FIXME: Δ Altitude could be negative


   type NED_Coordinates_Type is (DIM_NORTH, DIM_EAST, DIM_DOWN);
   type NED_Translation_Vector is array(NED_Coordinates_Type) of Length_Type;

   type Longitude_Array is array (Natural range <>) of Longitude_Type;
   type Latitude_Array is array (Natural range <>) of Latitude_Type;
   type Altitude_Array is array (Natural range <>) of Altitude_Type;

   type GPS_Fix_Type is (NO_FIX, FIX_2D, FIX_3D);


   -- Orientation
   subtype Roll_Type is Units.Angle_Type range -180.0 * Degree .. 180.0 * Degree;
   subtype Pitch_Type is Units.Angle_Type range -90.0 * Degree .. 90.0 * Degree;
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

   EARTH_RADIUS : constant Length_Type := 6378.137 * Kilo * Meter;

   METER_PER_LAT_DEGREE : constant Length_Angle_Ratio_Type := 111.111 * Kilo * Meter / Degree; -- average lat


   type Body_Type is record
      mass        : Mass_Type;
      position    : GPS_Loacation_Type;
      orientation : Orientation_Type;
      linear_velocity  : Linear_Velocity_Vector;
      angular_velocity : Angular_Velocity_Vector;
   end record;


   function Heading(mag_vector : Magnetic_Flux_Density_Vector; orientation : Orientation_Type) return Heading_Type;


   -- FIXME: this seems not to work yet
   function Distance( source : GPS_Loacation_Type; target: GPS_Loacation_Type ) return Length_Type;


   function To_Orientation( rotation : Rotation_Vector ) return Orientation_Type is
   (  wrap_Angle( rotation(X), Roll_Type'First, Roll_Type'Last ),
      wrap_Angle( rotation(Y), Pitch_Type'First, Pitch_Type'Last ),
      wrap_Angle( rotation(Z), Yaw_Type'First, Yaw_Type'Last ) );


   function To_NED_Translation( value : GPS_Translation_Type) return NED_Translation_Vector is
   ( DIM_NORTH => Cos(value.Latitude) * value.Longitude * METER_PER_LAT_DEGREE,
      DIM_EAST => value.Latitude * METER_PER_LAT_DEGREE,
      DIM_DOWN => -(value.Altitude) );


   function "-" (Left, Right : GPS_Loacation_Type) return GPS_Translation_Type is
   ( delta_Angle( Right.Longitude, Left.Longitude), delta_Angle( Right.Latitude, Left.Latitude ), Left.Altitude - Right.Altitude );

--     function "-" (Left : GPS_Loacation_Type; Right : GPS_Loacation_Type) return Translation_Vector is
--     ( X => Cos(Left.Latitude - Right.Latitude) * (Left.Longitude - Right.Longitude) * METER_PER_LAT_DEGREE,
--        Y => (Left.Latitude - Right.Latitude) * METER_PER_LAT_DEGREE,
--        Z => -(Left.Altitude - Right.Altitude) );

--     function "+" (Left : GPS_Loacation_Type; Right : Translation_Vector) return GPS_Loacation_Type is
--     ( Longitude => Left.Longitude + Right(X) , Altitude => Left.Altitude - Right(Z)



   function "+" (Left : Orientation_Type; Right : Rotation_Vector) return Orientation_Type is
     ( wrap_Angle( Angle_Type( Left.Roll ) + Right(X), Roll_Type'First, Roll_Type'Last ),
      mirror_Angle( Angle_Type( Left.Pitch) + Right(Y), Pitch_Type'First, Pitch_Type'Last ),
      wrap_Angle( Angle_Type( Left.Yaw) + Right(Z), Yaw_Type'First, Yaw_Type'Last ) ) with
   pre => Angle_Type( Left.Roll ) + Right(X) < Angle_Type'Last and
     Angle_Type( Left.Pitch) + Right(Y) <  Angle_Type'Last and
     Angle_Type( Left.Yaw) + Right(Z) <  Angle_Type'Last;

   function "-" (Left : Orientation_Type; Right : Rotation_Vector) return Orientation_Type is
   ( wrap_Angle( Left.Roll - Right(X), Roll_Type'First, Roll_Type'Last ),
         mirror_Angle( Left.Pitch - Right(Y), Pitch_Type'First, Pitch_Type'Last ),
         wrap_Angle( Left.Yaw - Right(Z), Yaw_Type'First, Yaw_Type'Last ) );


   function "-" (Left, Right : Orientation_Type) return Rotation_Vector is
   ( delta_Angle(Right.Roll, Left.Roll), Left.Pitch - Right.Pitch, Left.Yaw - Right.Yaw );




end Units.Navigation;
