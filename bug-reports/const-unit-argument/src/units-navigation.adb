with Units; use Units;

package body Units.Navigation with SPARK_Mode is

   function foo return Heading_Type is
      result : Angle_Type;

      -- SPARK GPL 2016: everything okay.
      -- SPARK Pro 18.0w: error with DEGREE 360; remove "constant" and it works
      A : Angle_Type := DEGREE_360;
   begin

      return Heading_Type( result );
   end foo;

   function bar return Length_Type is
      EPS : constant := 1.0E-12;
      pragma Assert (EPS > Float'Small);
   begin
      return 0.0*Meter;
   end bar;

end Units.Navigation;
