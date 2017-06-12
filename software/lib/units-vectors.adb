with Units.Numerics; use Units.Numerics;

pragma Elaborate_All(Units);

package body Units.Vectors with SPARK_Mode is

   function Sat_Add is new Saturated_Addition (Unit_Type);
   function Sat_Sub is new Saturated_Subtraction (Unit_Type);

   function Unit_Square (val : Unit_Type) return Unit_Type is
   begin
      if Sqrt (Unit_Type'Last) <= abs (val) then
         return Unit_Type'Last;
      else
         return val*val; -- TODO: fails (Sqrt is not modeled precisely)
      end if;
   end Unit_Square;

   procedure rotate
     (vector : in out Cartesian_Vector_Type;
      axis   :        Cartesian_Coordinates_Type;
      angle  :        Angle_Type)
   is
      result : Cartesian_Vector_Type := vector;

      co : constant Unit_Type := Cos (angle);
      si : constant Unit_Type := Sin (angle);
      pragma Assert (co in -1.0 .. 1.0);
      pragma Assert (si in -1.0 .. 1.0);
   begin
      case (axis) is
         when X =>
            result (Y) := Sat_Sub (co * vector(Y), si * vector(Z));
            result (Z) := Sat_Add (si * vector(Y), co * vector(Z));

         when Y =>
            result (X) := Sat_Add (si * vector(Z), co * vector(X));
            result (Z) := Sat_Sub (co * vector(Z), si * vector(X));

         when Z =>
            result (X) := Sat_Sub (co * vector(X), si * vector(Y));
            result (Y) := Sat_Add (si * vector(X), co * vector(Y));
      end case;
      vector := result;
   end rotate;

   function "abs" (vector : Cartesian_Vector_Type) return Unit_Type is
      xx : constant Unit_Type := Unit_Square (vector(X));
      yy : constant Unit_Type := Unit_Square (vector(Y));
      zz : constant Unit_Type := Unit_Square (vector(Z));
      len : constant Unit_type := Sat_Add (Sat_Add (xx, yy), zz);
      pragma Assert (len >= 0.0); -- TODO: fails. need lemma?
   begin
      return Sqrt (len);
   end "abs";

   function "abs" (vector : Angular_Vector) return Unit_Type is
      xx : constant Unit_Type := Unit_Square (vector(X));
      yy : constant Unit_Type := Unit_Square (vector(Y));
      zz : constant Unit_Type := Unit_Square (vector(Z));
      len : constant Unit_type := Sat_Add (Sat_Add (xx, yy), zz);
      pragma Assert (len >= 0.0); -- TODO: fails. need lemma?
   begin
      return Sqrt (len);
   end "abs";

   function "abs" (vector : Linear_Acceleration_Vector) return Linear_Acceleration_Type is
      xx : constant Unit_Type := Unit_Square (vector(X));
      yy : constant Unit_Type := Unit_Square (vector(Y));
      zz : constant Unit_Type := Unit_Square (vector(Z));
      len : constant Unit_type := Sat_Add (Sat_Add (xx, yy), zz);
      pragma Assert (len >= 0.0); -- TODO: fails. need lemma?
   begin
      return Linear_Acceleration_Type (Sqrt (len));
   end "abs";

   function Eye( n : Natural ) return Unit_Matrix is
      result : Unit_Matrix(1 .. n, 1 .. n) := (others => (others => 0.0));
   begin
      for i in result'Range loop
         result(i,i) := 1.0;
      end loop;
      return result;
   end Eye;

   function Ones( n : Natural ) return Unit_Matrix is
      result : constant Unit_Matrix(1 .. n, 1 .. n) := (others => (others => 1.0));
   begin
      return result;
   end Ones;

   function Zeros( n : Natural ) return Unit_Matrix is
      result : constant Unit_Matrix(1 .. n, 1 .. n) := (others => (others => 0.0));
   begin
      return result;
   end Zeros;

   procedure setOnes( A : in out Unit_Matrix; first : Natural; last : Natural) is null;

end Units.Vectors;
