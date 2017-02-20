
package Units with
     Spark_Mode is


    type Unit_Type is new Float with  -- As tagged Type? -> Generics with Unit_Type'Class
        Dimension_System =>
        ((Unit_Name => Meter, Unit_Symbol => 'm', Dim_Symbol => 'L'),
         (Unit_Name => Kilogram, Unit_Symbol => "kg", Dim_Symbol => 'M'),
         (Unit_Name => Second, Unit_Symbol => 's', Dim_Symbol => 'T'),
         (Unit_Name => Ampere, Unit_Symbol => 'A', Dim_Symbol => 'I'),
         (Unit_Name => Kelvin, Unit_Symbol => 'K', Dim_Symbol => "Theta"),
         (Unit_Name => Radian, Unit_Symbol => "Rad", Dim_Symbol => "A")),
   Default_Value => 0.0; 

   -- Base Units
   subtype Length_Type is Unit_Type with
        Dimension => (Symbol => 'm', Meter => 1, others => 0);  
 
   subtype Time_Type is Unit_Type with
        Dimension => (Symbol => 's', Second => 1, others => 0);   

   subtype Linear_Velocity_Type is Unit_Type with
        Dimension => (Meter => 1, Second => -1, others => 0);   

   -- Base units
   Meter    : constant Length_Type := Length_Type (1.0);
   Second   : constant Time_Type := Time_Type (1.0);

end Units;
