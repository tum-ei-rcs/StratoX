with Units.Numerics; use Units.Numerics;

package body Units.Vectors with SPARK_Mode is

   EPS : constant := 1.0E-12;

   function Sat_Add is new Saturated_Addition (Unit_Type);
   function Sat_Sub is new Saturated_Subtraction (Unit_Type);

   function Unit_Square (val : Unit_Type) return Unit_Type is
   begin
      if Sqrt (Unit_Type'Last) <= abs (val) then
         return Unit_Type'Last;
      elsif abs (val) < EPS then
         return Unit_Type (0.0);
      else
         return val*val;
      end if;
   end Unit_Square;

   procedure rotate
     (vector : in out Cartesian_Vector_Type;
      axis   :        Cartesian_Coordinates_Type;
      angle  :        Angle_Type) is
      result : Cartesian_Vector_Type := vector;

      --  computes numerically stable Cos(a)*v
      function Cos_Vec (a : Angle_Type; v : Unit_Type) return Unit_Type with Pre => True;
      function Cos_Vec (a : Angle_Type; v : Unit_Type) return Unit_Type is
         res : Unit_Type;
         c   : Unit_Type;
      begin
         if abs(a) < Angle_Type (EPS) then
            c := 1.0; -- cos (very small) is one
         else
            c := Cos (a);
         end if;
         c := Units.Clip_Unitcircle (c);

         if abs(v) < EPS then
            res := 0.0;
         else
            res := c * v;
         end if;
         return res;
      end Cos_Vec;

      --  computes numerically stable Sin(a)*v
      function Sin_Vec (a : Angle_Type; v : Unit_Type) return Unit_Type with Pre => True;
      function Sin_Vec (a : Angle_Type; v : Unit_Type) return Unit_Type is
         res : Unit_Type;
         s   : Unit_Type;
      begin
         if abs(a) < Angle_Type (EPS) then
            s := 0.0; -- sin (very small) is zero
         else
            s := Sin (a);
         end if;
         s := Units.Clip_Unitcircle (s);

         if abs(v) < EPS then
            res := 0.0;
         else
            res := s * v;
         end if;
         return res;
      end Sin_Vec;

   begin
      case (axis) is
         when X =>
            --  z is veeeery small sometimes: 2E-38. But float'valid passes.
            --  Only after the multiplication the compiler-inserted 'valid
            --  fails, because the result becomes a denormal.
            result (Y) := Sat_Sub (Cos_Vec (angle, vector(Y)), Sin_Vec (angle, vector(Z)));
            result (Z) := Sat_Add (Sin_Vec (angle, vector(Y)), Cos_Vec (angle, vector(Z)));

         when Y =>
            result (X) := Sat_Add (Cos_Vec (angle, vector(X)), Sin_Vec (angle, vector(Z)));
            result (Z) := Sat_Sub (Cos_Vec (angle, vector(Z)), Sin_Vec (angle, vector(X)));

         when Z =>
            result (X) := Sat_Sub (Cos_Vec (angle, vector(X)), Sin_Vec (angle, vector(Y)));
            result (Y) := Sat_Add (Sin_Vec (angle, vector(X)), Cos_Vec (angle, vector(Y)));
      end case;
      vector := result;
   end rotate;

   function "abs" (vector : Cartesian_Vector_Type) return Unit_Type is
      xx : constant Unit_Type := Unit_Square (vector(X));
      yy : constant Unit_Type := Unit_Square (vector(Y));
      zz : constant Unit_Type := Unit_Square (vector(Z));
   begin
      return Sqrt (Sat_Add (Sat_Add (xx, yy), zz));
   end "abs";

   function "abs" (vector : Angular_Vector) return Unit_Type is
      xx : constant Unit_Type := Unit_Square (vector(X));
      yy : constant Unit_Type := Unit_Square (vector(Y));
      zz : constant Unit_Type := Unit_Square (vector(Z));
   begin
      return Sqrt (Sat_Add (Sat_Add (xx, yy), zz));
   end "abs";

   function "abs" (vector : Linear_Acceleration_Vector) return Linear_Acceleration_Type is
      xx : constant Unit_Type := Unit_Square (vector(X));
      yy : constant Unit_Type := Unit_Square (vector(Y));
      zz : constant Unit_Type := Unit_Square (vector(Z));
   begin
      return Linear_Acceleration_Type (Sqrt (Sat_Add (Sat_Add (xx, yy), zz)));
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
