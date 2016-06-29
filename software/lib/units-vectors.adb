
with Units.Numerics; use Units.Numerics;

package body Units.Vectors is

procedure rotate(vector : in out Cartesian_Vector_Type; axis : Cartesian_Coordinates_Type; angle : Angle_Type) is
   result : Cartesian_Vector_Type := vector;
begin
   case (axis) is
      when X =>
         result(Y) := Cos(angle) * vector(Y) - Sin(angle) * vector(Z);
         result(Z) := Sin(angle) * vector(Y) + Cos(angle) * vector(Z);
      when Y =>
         result(X) :=  Cos(angle) * vector(X) + Sin(angle) * vector(Z);
         result(Z) := -Sin(angle) * vector(X) + Cos(angle) * vector(Z);
      when Z =>
         result(X) := Cos(angle) * vector(X) - Sin(angle) * vector(Y);
         result(Y) := Sin(angle) * vector(X) + Cos(angle) * vector(Y);
   end case;
   vector := result;
end rotate;


function "abs" (vector : Cartesian_Vector_Type) return Unit_Type is
begin
      return Unit_Type( Sqrt( vector(X)**2 + vector(Y)**2 + vector(Z)**2 ) );
end "abs";

end Units.Vectors;
