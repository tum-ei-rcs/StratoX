
with Units.Numerics; use Units.Numerics;

package body Units.Vectors is

procedure rotate(vector : in out Cartesian_Vector_Type; axis : Cartesian_Coordinates_Type; angle : Angle_Type) is
   result : Cartesian_Vector_Type := vector;
   Axis_A : Cartesian_Coordinates_Type;
   Axis_B : Cartesian_Coordinates_Type;
begin
   case (axis) is
      when X =>
         Axis_A := Y;
         Axis_B := Z;
      when Y =>
         Axis_A := X;
         Axis_B := Z;
      when Z =>
         Axis_A := X;
         Axis_B := Y;
   end case;
   result(Axis_A) := Cos(angle) * vector(Axis_A) - Sin(angle) * vector(Axis_B);
   result(Axis_B) := Sin(angle) * vector(Axis_A) + Sin(angle) * vector(Axis_B);
   vector := result;
end rotate;



end Units.Vectors;
