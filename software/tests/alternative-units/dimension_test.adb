
with Units; use Units;
with Units.Vectors; use Units.Vectors;


with CoSy; use CoSy;
use CoSy.Electric_Field_Pack;

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
    function "+"(Left, Right : Position_Type) return Position_Type is abstract;
    pragma Obsolescent("+", "Dont use it", Ada_05);
    -- ToDo: Check unreferenced pragma
    -- vl hilft inline?


    -- pragma Compile_Time_Error(boolean_EXPRESSION, static_string_EXPRESSION);
    -- ghost code inside function?


    function "+"(Left : Position_Type; Right : Translation_Type) return Position_Type is 
    ( Position_Type( Length_Type(Left) + Length_Type(Right) ) );

    function "-"(Left, Right : Position_Type) return Translation_Type is 
    ( Translation_Type( Length_Type(Left) - Length_Type(Right) ) );

    pos_one : Position_Type := 3.0;
    pos_two : Position_Type := 5.0;
    distance : Translation_Type := 1.0;


    -----------------------------------------
    -- Spatial Dimension Protection
    -----------------------------------------


    el_field : Electric_Field_Pack.Unit_Vector := ( 
                Electric_Field_Pack.Unit_X_Type( 2.0*Volt/Meter ),
                Electric_Field_Pack.Unit_Y_Type( 2.0*Volt/Meter ),
                Electric_Field_Pack.Unit_Z_Type( 2.0*Volt/Meter ) );


    el_field2 : Electric_Field_Vector2;


    pos3d : Translation_Vector;


    -----------------------------------------
    -- Generics Tests
    -----------------------------------------

    -- inout paramter
    procedure area( X : in out Translation_Type ) is   -- inout conserves unit
    begin
        null;
        -- X := X * X;   -- not possible
    end area;


    procedure integral( x : Unit_Type'Base; dt : Unit_Type'Base; y : out Unit_Type'Base) is
    begin
        y := x * dt;   -- no unit protection
    end integral;

    -- generic integral
    generic
        -- type Integrand_Type is private;         -- ERROR: expected type "Unit_Type"
        -- subtype Integrand_Type is Unit_Type;    -- ERROR: subtype declaration not allowed as generic parameter declaration
        -- type Integrand_Type is new Unit_Type;   -- ERROR: invalid operand types for operator "*"
        -- type Integrated_Type is new Unit_Type;    
        -- type Integration_Type is new Unit_Type; 
        
        type Integrand_Type is digits <>;    -- ERROR: invalid operand types for operator "*"
        type Integration_Type is digits <>;
        type Integrated_Type is digits <>;
    function generic_integral( x : Integrand_Type; t : Integration_Type ) return Integrated_Type;
    

    function generic_integral( x : Integrand_Type; t : Integration_Type ) return Integrated_Type is 
    begin
        --return x * t;    -- Problem: incompatible types, new destroys unit information
        return Integrated_Type( Unit_Type(x) * Unit_Type(t) );   -- possible, but no unit protection
        -- return Integrated_Type( x * t );
    end generic_integral;

    function velocity_integral is new generic_integral(Linear_Velocity_Type, Time_Type, Length_Type);

    my_duration : Time_Type := 30.0 * Second;
    my_velocity : Linear_Velocity_Type := 4.0 * Meter / Second;


    -----------------------------------------
    -- Class-Wide Test
    -----------------------------------------
    package Unit_Class is
        -- type UnitTest_Tag is tagged Float;  -- ERROR: missing "record"

        subtype Unit_Subtype is Unit_Type with Dimension => (others => 1);
        --subtype Length_Subtype is Unit_Subtype with Dimension => ( Meter => 1, others => 0);
        -- ERROR: parent type of "Length_Subtype" lacks dimension system

        type Unit_Tag is tagged record
            value : Unit_Type'Base;
        end record;   -- aspect "Dimension_System" must apply to numeric derived type declaration
   --     with Dimension_System =>
   --      ((Unit_Name => Meter, Unit_Symbol => 'm', Dim_Symbol => 'L'),
   --       (Unit_Name => Kilogram, Unit_Symbol => "kg", Dim_Symbol => 'M'),
   --       (Unit_Name => Second, Unit_Symbol => 's', Dim_Symbol => 'T'),
   --       (Unit_Name => Ampere, Unit_Symbol => 'A', Dim_Symbol => 'I'),
   --       (Unit_Name => Kelvin, Unit_Symbol => 'K', Dim_Symbol => "Theta"),
   --       (Unit_Name => Radian, Unit_Symbol => "Rad", Dim_Symbol => "A")),
   -- Default_Value => 0.0;;

        function "+" (u1 : Unit_Tag'Class; u2 : Unit_Tag'Class) return Unit_Tag is
        ( ( value => u1.value + u2.value ) );


        function Add (u1 : Unit_Tag'Class; u2 : Unit_Tag'Class) return Unit_Tag'Class is
        ( u1 + u2 );

        -- dist_c1 : Unit_Tag := ( value => 1.0 * Meter );   -- not possible to asign unit
        dist_c1 : Unit_Tag := ( value => 1.0 );
        dist_c2 : Unit_Tag := ( value => 1.0 );
    end Unit_Class;  -- Dimension System only applies to Numeric Types

    use Unit_Class;


    -----------------------------------------
    -- Prefix
    -----------------------------------------
    type Prefix is digits 10 range 1.0e-10 .. 1.0e10;
    subtype Quantity_Type is Unit_Type;
    -- subtype Prefix is Unit_Type;
    MyMilli : Prefix := 1.0e-3;

    function "*"( Left : Float; Right : Prefix ) return Unit_Type is
    ( Unit_Type( Left * Float(Right) ));

    function "*"( Left, Right : Prefix ) return Prefix is abstract;
    -- Todo: Compiler warning: Consider rewriting the prefix expression


    function "*"( Left : Unit_Type; Right : Prefix ) return Unit_Type is abstract;


    function "/"( Left : Unit_Type; Right : Prefix ) return Unit_Type is abstract;
    function "/"( Left : Prefix; Right : Unit_Type ) return Unit_Type is abstract;

    -- function "*"( Left : Prefix; Right : Unit_Type ) return Unit_Type is
    -- ( Unit_Type(Left) * Right ); -- loss of Units


--============================================================
-- Perform Tests
--============================================================
begin

    -----------------------------------------
    -- Absolute/Relative Tests
    -----------------------------------------
    distance := distance + 3.0*Meter;    -- legal
    pos_one := pos_one + distance;       -- legal
    distance := pos_one - pos_two;       -- legal
    -- my_velocity := pos_one / my_duration; -- illegal ✔
    -- pos_one := distance + pos_one;       -- illegal, keep order ✔
    -- pos_one := pos_one + pos_two;        -- illegal, abstract error (nasty)
    

    Put("Position 1: "); Put(Unit_Type(pos_one)); New_Line;
    Put("Distance: "); Put(distance); New_Line;

    -----------------------------------------
    -- Spatial Dimension Protection
    -----------------------------------------

    pos3d(X) := pos3d(X) + pos3d(Y);  -- should be illegal

    -- separate types required, array vector not possible

    -- el_field.x := el_field.x + el_field.y;

    el_field := el_field + el_field;

    Put("E-Field X: "); Put(Unit_Type(el_field.x)); New_Line;


    -----------------------------------------
    -- Generics Tests
    -----------------------------------------

    integral( my_duration, my_duration, distance );

    -- distance := velocity_integral(my_velocity, my_duration);
    Put("Distance: "); Put(distance); New_Line;

    -----------------------------------------
    -- Class-Wide Test
    -----------------------------------------
    dist_c1 := dist_c1 + dist_c2;
    Put("Class Distance: "); Put(dist_c1.value);



    -----------------------------------------
    -- Prefix
    -----------------------------------------
    my_duration := 1.0 * MyMilli * Second;  -- legal
    my_duration := 1.0 * (1.0 * MyMilli * Second);  -- legal, problem
    -- my_duration := MyMilli * Second; -- illegal, value required
    my_duration := MyMilli * 1.0 * Second; -- illegal ✔
    -- my_duration := 1.0 * Second * MyMilli; -- illegal ✔
    -- my_duration := (1.0 * MyMilli) / Second; -- illegal ✔
    -- my_duration := (1.0 * MyMilli) * (Unit_Type(1.0) / Second);
    my_duration := 1.0 * MyMilli * MyMilli * Second; -- illegal

    my_velocity := 1.0 * Meter / (1.0 * MyMilli * Second);


end Dimension_Test;
