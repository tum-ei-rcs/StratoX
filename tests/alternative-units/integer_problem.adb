
-- Minimal Example to produce "integer literal expected" error in Dimension Aspect
--
-- Steps to reproduce: 
--      * Dimension_System is applied on Integer type
--      * subtype Dimension is set to a negative integer literal
--
-- Wrong Behavior: -1 is a valid integer literal, however, compiler complains it is not
--
-- Additional Note: The Dimension System requires at least 2 dimensions. 
--      The reference manual states that only one is required.


procedure Dimension_Test is

    type Unit_Type is new Float
       	with Dimension_System => ( 
            (Unit_Name => Meter,    Unit_Symbol => 'm',   Dim_Symbol => 'L'),
            (Unit_Name => Kilogram, Unit_Symbol => "kg",  Dim_Symbol => 'M')
        );

    -- positive dimension works
    subtype Length_Type is Unit_Type
        with Dimension => (Symbol => 'm', Meter => 1, Kilogram => 0);

    A : constant Integer := 1;

    -- negative dimension fails with Error "integer literal expected"
    subtype Inverse_Length_Type is Unit_Type
        with Dimension => (Symbol => 'n', Meter => 1, Kilogram => 0);
	
begin

    null;

end Dimension_Test;
