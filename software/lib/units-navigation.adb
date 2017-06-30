with Units; use Units;
with SPARK.Float_Arithmetic_Lemmas; use SPARK.Float_Arithmetic_Lemmas;
--  with Logger;

package body Units.Navigation with SPARK_Mode is


   -- magnetic flux vecotor is pointing to the north and about 60° down to ground
   function Heading(mag_vector : Magnetic_Flux_Density_Vector; orientation : Orientation_Type) return Heading_Type is
      temp_vector : Cartesian_Vector_Type := ( Base_Unit_Type( mag_vector(X) ), Base_Unit_Type( mag_vector(Y) ), Base_Unit_Type( mag_vector(Z) ) );
      result : Angle_Type := 0.0 * Degree;
   begin
      -- rotate(temp_vector, Z, 45.0 * Degree);
      rotate(temp_vector, X, Angle_Type (orientation.Roll));
      rotate(temp_vector, Y, orientation.Pitch);

      -- Arctan: Only X = Y = 0 raises exception
      if temp_vector(Y) /= 0.0 or temp_vector(X) /= 0.0 then
         result := Arctan( -temp_vector(Y) , temp_vector(X) ); -- TODO: precond might fail
      end if;
      if result < 0.0 * Degree then
         result := result + Heading_Type'Last;
      end if;
      return Heading_Type( result );

   end Heading;


   --  phi=atan2(sin(delta_lon) * cos (lat2), cos lat1 * sin lat2 - sin lat1 * cos(lat2) * cos (delta_lon)
   function Bearing (source_location : GPS_Loacation_Type; target_location  : GPS_Loacation_Type) return Heading_Type is
      result : Angle_Type := 0.0 * Degree;
      y, x : Base_Unit_Type;

      ctla : constant Base_Unit_Type := Cos (target_location.Latitude);
      stla : constant Base_Unit_Type := Sin (target_location.Latitude);
      csla : constant Base_Unit_Type := Cos (source_location.Latitude);
      ssla : constant Base_Unit_Type := Sin (source_location.Latitude);
      --pragma Assert_And_Cut (ctla in -1.0 .. 1.0 and stla in -1.0 .. 1.0 and csla in -1.0 .. 1.0 and ssla in -1.0 .. 1.0);

      dlon : constant Angle_Type := delta_Angle (source_location.Longitude, target_location.Longitude);
   begin

      Lemma_Mul_Is_Contracting (Float(csla), Float (stla));
      Lemma_Mul_Is_Contracting (Float(ssla), Float (ctla));

      -- calculate angle between -180 .. 180 Degree
      if source_location.Longitude /= target_location.Longitude or
        source_location.Latitude /= target_location.Latitude
      then
         declare
            si : constant Base_Unit_Type := Sin (dlon);
         begin
            y := si * ctla;
            Lemma_Mul_Is_Contracting (Float(si), Float(ctla));
            pragma Assert (y in -1.0 .. 1.0);
         end;

         declare
            pragma Assert (csla in -1.0 .. 1.0);
            pragma Assert (stla in -1.0 .. 1.0);
            cs  : constant Base_Unit_Type := csla * stla;
            cd  : constant Base_Unit_Type := Cos (dlon);
            scc : Base_Unit_Type := ssla * ctla;
         begin

            pragma Assert (cs in -1.0 .. 1.0);
            pragma Assert (scc in -1.0 .. 1.0);
            pragma Assert (cd in -1.0 .. 1.0);
            Lemma_Mul_Is_Contracting (Float(scc), Float(cd));
            scc := scc * cd;
            pragma Assert (scc in -1.0 .. 1.0);
            x   := cs - scc;
         end;
         result := Arctan (Y => y, X => x, Cycle => DEGREE_360);
      end if;

      --  shift to Heading_Type
      if result < 0.0 * Degree then
         result := result + Heading_Type'Last;
      end if;
      return Heading_Type( result );
   end Bearing;
   pragma Unreferenced (Heading);


   --  From http://www.movable-type.co.uk/scripts/latlong.html
   --  based on the numerically largely stable "haversine"
   --  haversine = sin^2(delta_lat/2) + cos(lat1)*cos(lat2) * sin^2(delta_lon/2)
   --  c = 2 * atan2 (sqrt (haversine), sqrt (1-haversine))
   --  d = EARTH_RADIUS * c
   --  all of the checks below are proven.
   function Distance (source : GPS_Loacation_Type; target: GPS_Loacation_Type) return Length_Type is

      delta_lat : constant Angle_Type := Angle_Type(target.Latitude) - Angle_Type(source.Latitude);
      delta_lon : constant Angle_Type := Angle_Type(target.Longitude) - Angle_Type(source.Longitude);
      dlat_half : constant Angle_Type := delta_lat / Unit_Type (2.0);
      dlon_half : constant Angle_Type := delta_lon / Unit_Type (2.0);
      haversine : Base_Unit_Type;
      sdlat_half : Base_Unit_Type;
      sdlon_half : Base_Unit_Type;
      coscos : Base_Unit_Type;

   begin
      -- sin^2(dlat/2)
      declare
         s : constant Base_Unit_Type := Sin (dlat_half);
         pragma Assert (s in -1.0 .. 1.0);
      begin
         sdlat_half := s * s;
         Lemma_Mul_Is_Contracting (Float(s), Float(s));
      end;

      --  sin^2(dlon/2)
      declare
         s : constant Base_Unit_Type := Sin (dlon_half);
         pragma Assert (s in -1.0 .. 1.0);
      begin
         sdlon_half := s * s;
         Lemma_Mul_Is_Contracting (Float(s), Float(s));
      end;

      pragma Assert_And_Cut (sdlat_half in -1.0 .. 1.0 and sdlon_half in -1.0 .. 1.0);
      -- *all* analysis results are forgotten, except of what is mentioned in the above cut statement

      --  cos*cos
      declare
         cs : constant Base_Unit_Type := Cos (source.Latitude);
         ct : constant Base_Unit_Type := Cos (target.Latitude);
         pragma Assert (cs in -1.0 .. 1.0);
         pragma Assert (ct in -1.0 .. 1.0);
      begin
         coscos := cs * ct;
         Lemma_Mul_Is_Contracting (Float(cs), Float(ct)); -- with this, alt-ergo can conclude quickly in the next line
      end;
      pragma Assert (coscos in -1.0 .. 1.0);

      --  haversine
      declare
         cts : Base_Unit_Type;
      begin
         cts := coscos * sdlon_half;
         Lemma_Mul_Is_Contracting (Float(coscos), Float(sdlon_half));
         pragma Assert (cts in -1.0 .. 1.0);
         haversine := sdlat_half + cts;
      end;
      if haversine = 0.0 then
         --  numerically too close to zero. return null without further effort
         return 0.0*Meter;
      end if;

      -- finally: distance
      declare
         pragma Assert (haversine in 0.0 .. 1.0); -- TODO: fails (this is the whole point of haversine)
         invhav : constant Base_Unit_Type := 1.0 - haversine;
         pragma Assert (invhav >= 0.0);
         sqr1 : constant Base_Unit_Type := Sqrt (haversine);
         sqr2 : constant Base_Unit_Type := Sqrt (invhav);
         darc : Angle_Type;
         pragma Assert (sqr1 >= 0.0);
      begin
         if sqr1 = 0.0 and sqr2 = 0.0 then
            return 0.0*Meter; -- Arctan is undefined for that combination
         else
            darc := Arctan (sqr1, sqr2);
            pragma Assert (darc in 0.0 * Degree .. 180.0 * Degree);
            return 2.0 * EARTH_RADIUS * Ignore_Unit (darc); -- FIXME: type conv not allowed in versions later than GPL16
         end if;
      end;
   end Distance;


end Units.Navigation;
