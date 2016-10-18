
with Units; use Units;
with Units.Vectors; use Units.Vectors;


with CoSy; use CoSy;

with System.Dim.Float_IO;
with Ada.Text_IO; use Ada.Text_IO;

procedure Dimension_Test is

    package Unit_IO is new System.Dim.Float_IO( Unit_Type ); use Unit_IO;


    -----------------------------------------
    -- Absolute/Relative Tests
    -----------------------------------------
    type Position_Type is new Length_Type;
	subtype Translation_Type is Length_Type;

    type DateTime_Type is new Time_Type;
    subtype Duration_Type is Time_Type range 0.0*Second .. Time_Type'Last;


    -- make position addition illegal (pragma?)
    -- function "+"(Left, Right : Position_Type) return Position_Type is null;

    function "+"(Left : Position_Type; Right : Translation_Type) return Position_Type is 
    ( Position_Type( Length_Type(Left) + Length_Type(Right) ) );

    function "-"(Left, Right : Position_Type) return Translation_Type is 
    ( Translation_Type( Length_Type(Left) - Length_Type(Right) ) );

    pos_one : Position_Type := 3.0;
    pos_two : Position_Type := 5.0;
    distance : Translation_Type := 1.0;


    -----------------------------------------
    -- Spartial Dimension Protection
    -----------------------------------------


    el_field : Electric_Field_Pack.Unit_Vector := ( 
                Electric_Field_Pack.Unit_X_Type( 2.0*Volt/Meter ),
                2.0*Volt/Meter,
                2.0*Volt/Meter );

    el_field2 : Electric_Field_Vector2;


    pos3d : Translation_Vector;


    -----------------------------------------
    -- Generics Tests
    -----------------------------------------

    procedure area( X : in out Translation_Type ) is   -- inout conserves unit
    begin
        null;
        -- X := X * X;   -- not possible
    end area;


    generic
        type Area_Type is new Unit_Type;    -- new destroys unit information
    function areaTwo( X : Translation_Type ) return Area_Type;

    function areaTwo( X : Translation_Type ) return Area_Type is 
    begin
        -- return X**2;
        return Area_Type( 2.0 );
    end areaTwo;


    -----------------------------------------
    -- Class-Wide Test
    -----------------------------------------

    type Unit_Tag is tagged record
        value : Float;
    end record;

    function "+" (u1 : Unit_Tag'Class; u2 : Unit_Tag'Class) return Unit_Tag is
    ( ( value => u1.value + u2.value ) );


    function Add (u1 : Unit_Tag'Class; u2 : Unit_Tag'Class) return Unit_Tag'Class is
    ( u1 + u2 );



begin

    -----------------------------------------
    -- Absolute/Relative Tests
    -----------------------------------------
    distance := distance + 1.0*Meter;    -- legal
    pos_one := pos_one + distance;       -- legal
    --pos_one := distance + pos_one;       -- illegal, keep order ✔
    pos_one := pos_one + pos_two;        -- TODO: make this illegal


    Put("Distance: "); Put(distance);


    -----------------------------------------
    -- Spartial Dimension Protection
    -----------------------------------------

    pos3d(X) := pos3d(X) + pos3d(Y);  -- should be illegal

    -- seperate types required, array vector not possible

    el_field.x := el_field.x + el_field.y;

    el_field := el_field + el_field;

    Put("E-Field X:"); Put(Unit_Type(el_field.x));


end Dimension_Test;
