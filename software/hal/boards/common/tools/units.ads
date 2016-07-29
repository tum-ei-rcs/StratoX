-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Units
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Checked dimension system for physical calculations
--              Based on package System.Dim.MKS
--
-- ToDo:
-- [ ] Define all required types

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Numerics;

package Units with
     Spark_Mode is

   -- Basis Type

   type Unit_Type is new Float with  -- As tagged Type? -> Generics with Unit_Type'Class
        Dimension_System =>
        ((Unit_Name => Meter, Unit_Symbol => 'm', Dim_Symbol => 'L'),
         (Unit_Name => Kilogram, Unit_Symbol => "kg", Dim_Symbol => 'M'),
         (Unit_Name => Second, Unit_Symbol => 's', Dim_Symbol => 'T'),
         (Unit_Name => Ampere, Unit_Symbol => 'A', Dim_Symbol => 'I'),
         (Unit_Name => Kelvin, Unit_Symbol => 'K', Dim_Symbol => "Theta"),
         (Unit_Name => Radian, Unit_Symbol => "Rad", Dim_Symbol => "A"));

   type Unit_Array is array (Natural range <>) of Unit_Type;

   -- Base Units
   subtype Length_Type is Unit_Type with
        Dimension => (Symbol => 'm', Meter => 1, others => 0);

   subtype Mass_Type is Unit_Type with
        Dimension => (Symbol => "kg", Kilogram => 1, others => 0);

   subtype Time_Type is Unit_Type with
        Dimension => (Symbol => 's', Second => 1, others => 0);

   subtype Current_Type is Unit_Type with
        Dimension => (Symbol => 'A', Ampere => 1, others => 0);

   subtype Temperature_Type is Unit_Type with
        Dimension => (Symbol => 'K', Kelvin => 1, others => 0);

   subtype Angle_Type is Unit_Type with
        Dimension => (Symbol => "Rad", Radian => 1, others => 0);


   -- Derived Units

   -- mechanical
   subtype Frequency_Type is Unit_Type with
        Dimension => (Symbol => "Hz", Second => -1, others => 0);

   subtype Force_Type is Unit_Type with
        Dimension => (Symbol => "N", Kilogram => 1, Meter => 1, Second => -2, others => 0);

   subtype Energy_Type is Unit_Type with
        Dimension => (Symbol => "J", Kilogram => 1, Meter => 2, Second => -2, others => 0);

   subtype Power_Type is Unit_Type with
        Dimension => (Symbol => "W", Kilogram => 1, Meter => 2, Second => -3, others => 0);

   subtype Pressure_Type is Unit_Type with
        Dimension => (Symbol => "Pa", Kilogram => 1, Meter => -1, Second => -2, others => 0);

   -- electromagnetic
   subtype Voltage_Type is Unit_Type with
        Dimension =>
        (Symbol   => 'V',
         Meter    => 2,
         Kilogram => 1,
         Second   => -3,
         Ampere   => -1,
         others   => 0);

   subtype Charge_Type is Unit_Type with
        Dimension => (Symbol => 'C', Second => 1, Ampere => 1, others => 0);

   subtype Capacity_Type is Unit_Type with
        Dimension =>
        (Symbol   => 'F',
         Kilogram => -1,
         Meter    => -2,
         Second   => 4,
         Ampere   => 2,
         others   => 0);

   subtype Resistivity_Type is Unit_Type with
        Dimension =>
        (Symbol   => "Ω",
         Kilogram => 1,
         Meter    => 2,
         Second   => -2,
         Ampere   => -3,
         others   => 0);

   subtype Inductivity_Type is Unit_Type with
        Dimension =>
        (Symbol   => 'H',
         Kilogram => 1,
         Meter    => 2,
         Second   => -2,
         Ampere   => -2,
         others   => 0);

   subtype Magnetic_Flux_Type is Unit_Type with
        Dimension =>
        (Symbol   => "Wb",
         Kilogram => 1,
         Meter    => 2,
         Second   => -2,
         Ampere   => -1,
         others   => 0);

   subtype Magnetic_Flux_Density_Type is Unit_Type with
        Dimension => (Symbol => 'T', Kilogram => 1, Second => -2, Ampere => -1, others => 0);

   -- further important dimensions
   subtype Area_Type is Unit_Type with
        Dimension => (Symbol => "m^2", Meter => 2, others => 0);

   subtype Volume_Type is Unit_Type with
        Dimension => (Symbol => "m^3", Meter => 3, others => 0);

   subtype Linear_Velocity_Type is Unit_Type with
        Dimension => (Meter => 1, Second => -1, others => 0);

   subtype Angular_Velocity_Type is Unit_Type with
        Dimension => (Radian => 1, Second => -1, others => 0);

   subtype Linear_Acceleration_Type is Unit_Type with
        Dimension => (Meter => 1, Second => -2, others => 0);

   subtype Angular_Acceleration_Type is Unit_Type with
        Dimension => (Radian => 1, Second => -2, others => 0);

   -- Prefix
   subtype Prefix_Type is Unit_Type;
   --type Prefix_Type is digits 2 range 1.0e-24 .. 1.0e+24;
   Yocto : constant Prefix_Type := Prefix_Type (1.0e-24);
   Zepto : constant Prefix_Type := Prefix_Type (1.0e-21);
   Atto  : constant Prefix_Type := Prefix_Type (1.0e-18);
   Femto : constant Prefix_Type := Prefix_Type (1.0e-15);
   Pico  : constant Prefix_Type := Prefix_Type (1.0e-12);
   Nano  : constant Prefix_Type := Prefix_Type (1.0e-9);
   Micro : constant Prefix_Type := Prefix_Type (1.0e-6);
   Milli : constant Prefix_Type := Prefix_Type (1.0e-3);
   Centi : constant Prefix_Type := Prefix_Type (1.0e-2);
   Deci  : constant Prefix_Type := Prefix_Type (1.0e-1);

   Deca  : constant Prefix_Type := Prefix_Type (1.0e+1);
   Hecto : constant Prefix_Type := Prefix_Type (1.0e+2);
   Kilo  : constant Prefix_Type := Prefix_Type (1.0e+3);
   Mega  : constant Prefix_Type := Prefix_Type (1.0e+6);
   Giga  : constant Prefix_Type := Prefix_Type (1.0e+9);
   Tera  : constant Prefix_Type := Prefix_Type (1.0e+12);
   Peta  : constant Prefix_Type := Prefix_Type (1.0e+15);
   Exa   : constant Prefix_Type := Prefix_Type (1.0e+18);
   Zetta : constant Prefix_Type := Prefix_Type (1.0e+21);
   Yotta : constant Prefix_Type := Prefix_Type (1.0e+24);

--     type The_Prefix_Type is (
--     Yocto,
--     Zepto,
--     Atto ,
--     Femto,
--     Pico ,
--     Nano ,
--     Micro,
--     Milli,
--     Centi,
--     Deci ,
--     Deca ,
--     Hecto,
--     Kilo ,
--     Mega ,
--     Giga ,
--     Tera ,
--     Peta ,
--     Exa  ,
--     Zetta,
--     Yotta );
--
--     for The_Prefix_Type use (
--     Yocto => -24,
--     Zepto => -21,
--     Atto  => -18,
--     Femto => -15,
--     Pico  => -12,
--     Nano  => -9,
--     Micro => -6,
--     Milli => -3,
--     Centi => -2,
--     Deci  => -1,
--     Deca  =>  1,
--     Hecto =>  2,
--     Kilo  =>  3,
--     Mega  =>  6,
--     Giga  =>  9,
--     Tera  =>  12,
--     Peta  =>  15,
--     Exa   =>  18,
--     Zetta =>  21,
--     Yotta =>  24 );
--
--
--     -- only multiplying of prefixes is allowed
--  --     function "*" (Left : Float; Right : The_Prefix_Type) return Unit_Type is
--  --        ( if The_Prefix_Type'Enum_Rep(Right) < 0 then Unit_Type( Left / (1.0**(-The_Prefix_Type'Enum_Rep(Right))))
--  --        else Unit_Type(Left * (1.0**The_Prefix_Type'Enum_Rep(Right))) );
--  --         ( 10.0**The_Prefix_Type'Value(Left) * Right );
--
--  function "*" (Left : Float; Right : The_Prefix_Type) return Unit_Type is
--  ( Unit_Type( case Right is
--     when Yocto => Left * 1.0e-24,
--     when Zepto => Left * 1.0e-21,
--     when Atto  => Left * 1.0e-18,
--     when Femto => Left * 1.0e-15,
--     when Pico  => Left * 1.0e-12,
--     when Nano  => Left * 1.0e-9,
--     when Micro => Left * 1.0e-6,
--     when Milli => Left * 1.0e-3,
--     when Centi => Left * 1.0e-2,
--     when Deci  => Left * 1.0e-1,
--     when Deca  => Left * 1.0e1,
--     when Hecto => Left * 1.0e2,
--     when Kilo  => Left * 1.0e3,
--     when Mega  => Left * 1.0e6,
--     when Giga  => Left * 1.0e9,
--     when Tera  => Left * 1.0e12,
--     when Peta  => Left * 1.0e15,
--     when Exa   => Left * 1.0e18,
--     when Zetta => Left * 1.0e21,
--     when Yotta => Left * 1.0e24 ) );


--  function "*" (Left : Float; Right : Prefix_Type) return Unit_Type is
--          ( Unit_Type( Left * Float(Right) ) );

   -- Base units
   Meter       : constant Length_Type := Length_Type (1.0);

   Kilogram : constant Mass_Type := Mass_Type (1.0);
   Gram     : constant Mass_Type := Mass_Type (1.0e-3);

   Second       : constant Time_Type := Time_Type (1.0);

   Ampere : constant Current_Type := Current_Type (1.0);

   Kelvin : constant Temperature_Type := Temperature_Type (1.0);

   -- Angular Units
   Radian    : constant Angle_Type := Angle_Type (1.0);
   Degree    : constant Angle_Type := Angle_Type (2.0 * Ada.Numerics.Pi / 360.0);
   Evolution : constant Angle_Type := Angle_Type (2.0 * Ada.Numerics.Pi);

   -- Derived Units
   Newton : constant Force_Type := Force_Type (1.0);

   Joule : constant Energy_Type := Energy_Type (1.0);

   Watt : constant Power_Type := Power_Type (1.0);

   Ohm : constant Resistivity_Type := Resistivity_Type (1.0);

   Pascal : constant Pressure_Type := Pressure_Type (1.0);

   Volt : constant Voltage_Type := Voltage_Type (1.0);

   Coulomb : constant Charge_Type := Charge_Type(1.0);

   Farad : constant Capacity_Type := Capacity_Type(1.0);

   Weber : constant Magnetic_Flux_Type := Magnetic_Flux_Type(1.0);

   Tesla : constant Magnetic_Flux_Density_Type := Magnetic_Flux_Density_Type(1.0);

   Henry : constant Inductivity_Type := Inductivity_Type(1.0);

   Hertz : constant Frequency_Type := Frequency_Type (1.0);

   -- Non SI but metric
   Minute : constant Time_Type := 60.0 * Second;
   Hour   : constant Time_Type := 60.0 * Minute;
   Day    : constant Time_Type := 24.0 * Hour;

   Tonne    : constant Mass_Type     := 1_000.0 * Kilogram;
   Angstrom : constant Length_Type   := 1.0 * Nano * Meter;
   Litre    : constant Volume_Type   := 1.0 * (1.0 * Deci * Meter)**3;
   Bar      : constant Pressure_Type := 1_000.0 * Hecto * Pascal;
   Gauss    : constant Magnetic_Flux_Density_Type := 0.1 * Tesla;

   -- Constants
   GRAVITY : constant Linear_Acceleration_Type := 9.81 * Meter / (Second**2);

   CELSIUS_0 : constant Temperature_Type := 273.15 * Kelvin;

   DEGREE_360 : constant Angle_Type := 360.0 * Degree;
   RADIAN_2PI : constant Angle_Type := 2.0 * Radian;

   -- Physical constants
   SPEED_OF_LIGHT   : constant Linear_Velocity_Type     := 299_792_458.0 * Meter / Second;
   PLANCK_CONSTANT  : constant Unit_Type                := 6.626_070_040 * Joule * Second;
   GRAVITY_CONSTANT : constant Linear_Acceleration_Type := 127_137.6 * Kilo * Meter / (Hour**2);

   -- converts Real_Time to Time_Type, precision is Nanosecond
   function To_Time
     (rtime : Ada.Real_Time.Time) return Time_Type is
     (Time_Type
        (Float ((rtime - Ada.Real_Time.Time_First) / Ada.Real_Time.Microseconds (1)) * Float(1.0e-6)));

   function To_Time
     (rtime : Ada.Real_Time.Time_Span) return Time_Type is
     (Time_Type
        (Float ((rtime) / Ada.Real_Time.Microseconds (1)) * Float(1.0e-6)));

    function To_Time_Span(time : Time_Type) return Ada.Real_Time.Time_Span is
     ( Ada.Real_Time.Microseconds ( Integer( Float(time)/Float(1.0e-6) ) ) );


   function "+"( Left : Ada.Real_Time.Time; Right : Time_Type ) return Ada.Real_Time.Time is
   ( Left + Ada.Real_Time.Microseconds ( Integer( Float(Right)/Float(1.0e-6) ) ) );


   -- wrap angle between two values
   -- idea: shift range to 0 .. X, wrap with mod, shift back
   function wrap_Angle( angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type is
   ( Angle_Type'Remainder( (angle - min - (max-min)/2.0) , (max-min) ) + (max+min)/2.0 );
--     with
--     pre => max > min,
--     post => wrap_Angle'Result in min .. max;
-- if angle - min < 0.0 * Degree then Angle_Type'Remainder( (angle - min), (max-min) ) + max else


  -- procedure Saturate(input : Unit_Type; output : in out Unit_Type);


   -- function Radian( degree : Float ) return Float

   function average( signal : Unit_Array ) return Unit_Type;


   -- Image functions
   function Image (unit : Unit_Type) return String;

   function AImage (unit : Angle_Type) return String;
   function RImage (unit : Angle_Type) return String;

end Units;
