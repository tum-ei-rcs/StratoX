
with Units; use Units;
with Generic_Unit_Vectors;

pragma Elaborate_All(Generic_Unit_Vectors);
package CoSy with SPARK_Mode is


   type Spartial_Type is new Float with
        Dimension_System =>
        ((Unit_Name => Meter_X, Unit_Symbol => "m_x", Dim_Symbol => "Lx"),
         (Unit_Name => Meter_Y, Unit_Symbol => "m_y", Dim_Symbol => "Ly"),
         (Unit_Name => Meter_Z, Unit_Symbol => "m_z", Dim_Symbol => "Lz")); 


    package Electric_Field_Pack is new Generic_Unit_Vectors(Electric_Field_Type);
    use Electric_Field_Pack;

    subtype Electric_Field_Vector is Electric_Field_Pack.Unit_Vector;
    function "+" is new Electric_Field_Pack.addition;

    subtype Electric_Field_Vector2 is Electric_Field_Pack.Unit_Vector2;

    type CoSy_Type is null record;


end CoSy;
