with Units.Numerics; use Units.Numerics;

package body Units.Vectors is

   procedure rotate
     (vector : in out Cartesian_Vector_Type;
      axis   :        Cartesian_Coordinates_Type;
      angle  :        Angle_Type) is
      result : Cartesian_Vector_Type := vector;

   begin
      case (axis) is
         when X =>
            result (Y) :=  Cos (angle) * vector (Y) - Sin (angle) * vector (Z);
            result (Z) :=  Sin (angle) * vector (Y) + Cos (angle) * vector (Z);

         when Y =>
            result (X) :=  Cos (angle) * vector (X) + Sin (angle) * vector (Z);
            result (Z) := -Sin (angle) * vector (X) + Cos (angle) * vector (Z);

         when Z =>
            result (X) :=  Cos (angle) * vector (X) - Sin (angle) * vector (Y);
            result (Y) :=  Sin (angle) * vector (X) + Cos (angle) * vector (Y);
      end case;
      vector := result;
   end rotate;

   function "abs" (vector : Cartesian_Vector_Type) return Unit_Type is
   begin
      return Unit_Type (Sqrt (vector (X)**2 + vector (Y)**2 + vector (Z)**2));
   end "abs";

   function "abs" (vector : Angular_Vector) return Unit_Type is
   begin
      return Unit_Type (Sqrt (vector (X)**2 + vector (Y)**2 + vector (Z)**2));
   end "abs";

   function "abs" (vector : Linear_Acceleration_Vector) return Linear_Acceleration_Type is
   begin
      return Linear_Acceleration_Type(Sqrt (vector (X)**2 + vector (Y)**2 + vector (Z)**2));
   end "abs";



   function Ones( n : Natural ) return Unit_Matrix is
      result : Unit_Matrix(1 .. n, 1 .. n) := (others => (others => 0.0));
   begin
      for i in result'Range loop
         result(i,i) := 1.0;
      end loop;
      return result;
   end Ones;


end Units.Vectors;
