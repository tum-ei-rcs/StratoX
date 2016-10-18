
package body Generic_Unit_Vectors with SPARK_Mode is


  function addition(Left, Right : Unit_Vector) return Unit_Vector is
  begin
    return (Left.x + Right.x, Left.y + Right.y, Left.z + Right.z);
  end addition;

end Generic_Unit_Vectors;
