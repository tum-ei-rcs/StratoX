package units with SPARK_Mode is

   type Unit_Type is new Float with  -- As tagged Type? -> Generics with Unit_Type'Class
        Dimension_System =>
        ((Unit_Name => Meter, Unit_Symbol => 'm', Dim_Symbol => 'L'),
         (Unit_Name => Kilogram, Unit_Symbol => "kg", Dim_Symbol => 'M'),
         (Unit_Name => Second, Unit_Symbol => 's', Dim_Symbol => 'T'),
         (Unit_Name => Ampere, Unit_Symbol => 'A', Dim_Symbol => 'I'),
         (Unit_Name => Kelvin, Unit_Symbol => 'K', Dim_Symbol => "Theta"),
         (Unit_Name => Radian, Unit_Symbol => "Rad", Dim_Symbol => "A")),
   Default_Value => 0.0;

   subtype Angle_Type is Unit_Type with
     Dimension => (Symbol => "Rad", Radian => 1, others => 0);


   Radian     : constant Angle_Type := Angle_Type (1.0);
   RADIAN_2PI : constant Angle_Type := 2.0 * Radian;


   -- idea: shift range to 0 .. X, wrap with mod, shift back
   --function wrap_Angle( angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type is
--     ( Angle_Type'Remainder( (angle - min - (max-min)/2.0) , (max-min) ) + (max+min)/2.0 );
   -- FIXME: Spark error: unbound symbol 'Floating.remainder_'
   -- ( if angle > max then max elsif angle < min then min else angle );
--     with
--     pre => max > min,
--     post => wrap_Angle'Result in min .. max;
-- if angle - min < 0.0 * Degree then Angle_Type'Remainder( (angle - min), (max-min) ) + max else

   function wrap_angle2 (angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type
     with Pre => min <= 0.0 * Radian and then
     max >= 0.0 * Radian and then
     max > min and then
     max < Angle_Type'Last / 2.0 and then
     min > Angle_Type'First / 2.0,
     Post => wrap_angle2'Result >= min and wrap_angle2'Result <= max;
   --  Must make no assumptions on input 'angle' here, otherwise caller might fail if it isn't SPARK.

end units;
