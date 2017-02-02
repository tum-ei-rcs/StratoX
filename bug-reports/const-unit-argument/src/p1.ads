with Units; use Units;

package p1 with SPARK_Mode is

   function Arctan
     (Y     : Unit_Type'Base;
      X     : Unit_Type'Base := 1.0;
      Cycle : Angle_Type) return Angle_Type
     with post => Arctan'Result in -Cycle/2.0 .. Cycle/2.0;

end p1;
