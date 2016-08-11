with Units.Numerics; use Units.Numerics;
with Units; use Units;


package body Units.Navigation is


   -- magnetic flux vecotor is pointing to the north and about 60° down to ground
   function Heading(mag_vector : Magnetic_Flux_Density_Vector; orientation : Orientation_Type) return Heading_Type is
      temp_vector : Cartesian_Vector_Type := Cartesian_Vector_Type(mag_vector);
      result : Angle_Type := 0.0 * Degree;
   begin
      -- rotate(temp_vector, Z, 45.0 * Degree);
      rotate(temp_vector, X, orientation.Roll);
      rotate(temp_vector, Y, orientation.Pitch);

      -- Logger.log_console(Logger.DEBUG, "Rot vec:" & Image(temp_vector(X) * 1.0e6) & ", " & Image(temp_vector(Y) * 1.0e6) & ", " & Image(temp_vector(Z) * 1.0e6) );

      -- Arctan: Only X = Y = 0 raises exception
      if temp_vector(Y) /= 0.0 or temp_vector(X) /= 0.0 then
         result := Arctan( -temp_vector(Y) , temp_vector(X) );
      end if;
      if result < 0.0 * Degree then
         result := result + Heading_Type'Last;
      end if;
      return Heading_Type( result );

   end Heading;


   -- θ = atan2( sin Δλ ⋅ cos φ2 , cos φ1 ⋅ sin φ2 − sin φ1 ⋅ cos φ2 ⋅ cos Δλ )
   -- φ is lat, λ is long
   function Heading(source_location : GPS_Loacation_Type;
                    target_location  : GPS_Loacation_Type)
                    return Heading_Type is
      result : Angle_Type := 0.0 * Degree;
   begin
      -- calculate angle between -180° and 180°
      if source_location.Longitude /= target_location.Longitude or source_location.Latitude /= target_location.Latitude then
         result := Arctan( Sin( delta_Angle( source_location.Longitude,
                                           target_location.Longitude ) ) *
                         Cos( target_location.Latitude ),
                         Cos( source_location.Latitude ) * Sin( target_location.Latitude ) -
                         Sin( source_location.Latitude ) * Cos( target_location.Latitude ) *
                         Cos( delta_Angle( source_location.Longitude,
                                      target_location.Longitude ) ),
                     DEGREE_360
                        );
      end if;

      -- Constrain to Heading_Type
      if result < 0.0 * Degree then
         result := result + Heading_Type'Last;
      end if;
      return Heading_Type( result );
   end Heading;
   pragma Unreferenced (Heading);


   -- From http://www.movable-type.co.uk/scripts/latlong.html
   -- a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
   function Distance( source : GPS_Loacation_Type; target: GPS_Loacation_Type ) return Length_Type is
      haversine : Unit_Type;
   begin
      haversine := Sin( delta_Angle( source.Latitude, target.Latitude ) / Unit_Type(2.0) )**2.0 +
                   Cos( source.Latitude ) * Cos( source.Latitude )  *
                   Sin( delta_Angle( source.Longitude, target.Longitude ) / Unit_Type(2.0) )**2.0;
      return  2.0 * EARTH_RADIUS * Unit_Type( Arctan( Unit_Type( Sqrt( haversine ) ), Unit_Type( Sqrt( Unit_Type(1.0) - haversine) ) ) );
   end Distance;





end Units.Navigation;
