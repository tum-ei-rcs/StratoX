package body p1 with SPARK_Mode is

   function Arctan
     (Y     : Unit_Type'Base;
      X     : Unit_Type'Base := 1.0;
      Cycle : Angle_Type) return Angle_Type
   is
   begin
      return 1.0 * Degree;
   end Arctan;

end p1;
