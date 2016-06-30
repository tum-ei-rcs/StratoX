package body Units.Navigation is

   function Heading(mag_vector : Magnetic_Flux_Density_Vector; orientation : Orientation_Type) return Heading_Type is
      temp_vector : Cartesian_Vector_Type := Cartesian_Vector_Type(mag_vector);
      result : Angle_Type := 0.0 * Degree;
   begin
      -- rotate(temp_vector, Z, 45.0 * Degree);
      rotate(temp_vector, X, -orientation.Roll);
      rotate(temp_vector, Y, -orientation.Pitch);

      -- Arctan: Only X = Y = 0 raises exception
      if temp_vector(Y) /= 0.0 or temp_vector(X) /= 0.0 then
         result := Arctan( temp_vector(Y) , temp_vector(X) );
      end if;
      if result < 0.0 * Degree then
         result := result + Heading_Type'Last;
      end if;
      return Heading_Type( result );

   end Heading;


end Units.Navigation;
