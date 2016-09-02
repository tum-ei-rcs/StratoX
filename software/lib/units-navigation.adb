with Units; use Units;

--  with Logger;

package body Units.Navigation with SPARK_Mode is


   -- magnetic flux vecotor is pointing to the north and about 60° down to ground
   function Heading(mag_vector : Magnetic_Flux_Density_Vector; orientation : Orientation_Type) return Heading_Type is
      temp_vector : Cartesian_Vector_Type := ( Unit_Type( mag_vector(X) ), Unit_Type( mag_vector(Y) ), Unit_Type( mag_vector(Z) ) );
      result : Angle_Type := 0.0 * Degree;
   begin
      -- rotate(temp_vector, Z, 45.0 * Degree);
      rotate(temp_vector, X, orientation.Roll);
      rotate(temp_vector, Y, orientation.Pitch);

      -- Logger.log_console(Logger.DEBUG, "Rot vec:" & Image(temp_vector(X) * 1.0e6) & ", "
      --  & Image(temp_vector(Y) * 1.0e6) & ", " & Image(temp_vector(Z) * 1.0e6) );

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



   function Clip_Unitcircle (X : Unit_Type) return Unit_Type is
   begin
      if X < Unit_Type (-1.0) then
         return Unit_Type (-1.0);
      elsif X > Unit_Type (1.0) then
         return Unit_Type (1.0);
      end if;
      return X;
   end Clip_Unitcircle;



   --  From http://www.movable-type.co.uk/scripts/latlong.html
   --  based on the numerically largely stable "haversine"
   --  haversine = sin^2(delta_lat/2) + cos(lat1)*cos(lat2) * sin^2(delta_lon/2)
   --  c = 2 * atan2 (sqrt (haversine), sqrt (1-haversine))
   --  d = EARTH_RADIUS * c
   --  all of the checks below are proven.
   function Distance (source : GPS_Loacation_Type; target: GPS_Loacation_Type) return Length_Type is
      EPS : constant := 1.0E-12;
      pragma Assert (EPS > Float'Small);

      delta_lat : constant Angle_Type := Angle_Type(target.Latitude) - Angle_Type(source.Latitude);
      delta_lon : constant Angle_Type := Angle_Type(target.Longitude) - Angle_Type(source.Longitude);
      dlat_half : constant Angle_Type := delta_lat / Unit_Type (2.0);
      dlon_half : constant Angle_Type := delta_lon / Unit_Type (2.0);
      haversine : Unit_Type;
      sdlat_half : Unit_Type;
      sdlon_half : Unit_Type;
      coscos : Unit_Type;

   begin
      --  sin^2(dlat/2): avoid underflow
      sdlat_half := Sin (dlat_half);
      --sdlat_half := Clip_Unitcircle (sdlat_half);
      if abs(sdlat_half) > EPS then
         sdlat_half := sdlat_half * sdlat_half;
      else
         sdlat_half := Unit_Type (0.0);
      end if;
      --pragma Assert (Float'Safe_First <= Float (sdlat_half) and Float'Safe_Last >= Float (sdlat_half)); -- OK
      -- clip inaccuracy overshoots, which helps the provers tremendously
      sdlat_half := Clip_Unitcircle (sdlat_half); -- sin*sin should only exceed 1.0 by imprecision: OK

      --  sin^2(dlon/2): avoid underflow
      sdlon_half := Sin (dlon_half);
      --sdlon_half := Clip_Unitcircle (sdlon_half);
      if abs(sdlon_half) > EPS then
         sdlon_half := sdlon_half * sdlon_half;
      else
         sdlon_half := Unit_Type (0.0);
      end if;
      sdlon_half := Clip_Unitcircle (sdlon_half); -- cos*cos should only exceed 1.0 by imprecision: OK

      --  cos*cos
      declare
         cs : constant Unit_Type := Cos (source.Latitude);
         ct : constant Unit_Type := Cos (target.Latitude);
      begin
         --pragma Assert (ct in Unit_Type (-1.0) .. Unit_Type (1.0)); -- OK
         --pragma Assert (cs in Unit_Type (-1.0) .. Unit_Type (1.0)); -- OK

         coscos := ct * cs; -- OK
         if abs(coscos) < Unit_Type (EPS) then
            coscos := Unit_Type (0.0);
         end if;
         -- clip inaccuracy overshoots, which helps the provers tremendously
         coscos := Clip_Unitcircle (coscos); -- cos*cos should only exceed 1.0 by imprecision: OK
      end;

      --  haversine
      declare
         cts : Unit_Type;
      begin
         --  avoid underflow
         if abs(coscos) > Unit_Type (EPS) and then abs(sdlon_half) > Unit_Type (EPS)
         then
            --pragma Assert (coscos in Unit_Type'Safe_First .. Unit_Type'Safe_Last and sdlon_half in Unit_Type'Safe_First..Unit_Type'Safe_Last); -- OK
            --  both numbers here are sufficiently different from zero
            --  both numbers are valid numerics
            --  both are large enough to avoid underflow
            cts := coscos * sdlon_half; -- Z3 can prove this steps=default, timeout=60, level=2
         else
            cts := Unit_Type (0.0);
         end if;
         if abs(sdlat_half) > Unit_Type (EPS) and then abs(cts) > Unit_Type (EPS) then
            haversine := sdlat_half + cts;
            if haversine > Unit_Type (1.0) then
               haversine := Unit_Type (1.0);
            end if;
         else
            haversine := Unit_Type (0.0);
         end if;
      end;
      declare
         function Sat_Sub_Unit is new Saturated_Subtraction (Unit_Type);
         invhav : constant Unit_Type := Sat_Sub_Unit (Unit_Type (1.0), haversine);
      begin
         return 2.0 * EARTH_RADIUS * Unit_Type (Arctan (Sqrt (haversine), Sqrt (invhav)));
      end;
   end Distance;


end Units.Navigation;
