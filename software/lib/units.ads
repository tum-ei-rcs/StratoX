-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
-- Module: Units
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Checked dimension system for physical calculations
--              Based on package System.Dim.MKS
-- 
-- ToDo:
-- [ ] Define all required types
	

with Ada.Real_Time; use Ada.Real_Time;

package Units is

type Unit_Type is new Float
   	with Dimension_System => ( 
		(Unit_Name => Meter,    Unit_Symbol => 'm',   Dim_Symbol => 'L'), 
		(Unit_Name => Kilogram, Unit_Symbol => "kg",  Dim_Symbol => 'M'), 
		(Unit_Name => Second,   Unit_Symbol => 's',   Dim_Symbol => 'T'),
		(Unit_Name => Ampere,   Unit_Symbol => 'A',   Dim_Symbol => 'I'),
		(Unit_Name => Kelvin,   Unit_Symbol => 'K',   Dim_Symbol => "Theta"),
		(Unit_Name => Degree,   Unit_Symbol => "deg", Dim_Symbol => "A")
    );


-- Base Units
subtype Length_Type is Unit_Type
	with Dimension => (Symbol => 'm', Meter => 1, others => 0);

subtype Mass_Type is Unit_Type 
	with Dimension => (Symbol => "kg", Kilogram => 1, others => 0);

subtype Time_Type is Unit_Type 
	with Dimension => (Symbol => 's', Second => 1, others => 0);

subtype Current_Type is Unit_Type 
	with Dimension => (Symbol => 'A', Ampere => 1, others => 0);

subtype Temperature_Type is Unit_Type 
	with Dimension => (Symbol => 'K', Ampere => 1, others => 0);

subtype Angle_Type is Unit_Type 
	with Dimension => (Symbol => "deg", Degree => 1, others => 0);


-- Derived Units
subtype Pressure_Type is Unit_Type 
	with Dimension => (Symbol => "Pa", Kilogram => 1, Meter => -1, Second => -2, others => 0);

subtype Voltage_Type is Unit_Type
	with Dimension => (Symbol => 'V', Meter => 2, Kilogram => 1, Second => -3, Ampere => -1, others => 0);

subtype Frequency_Type is Unit_Type 
	with Dimension => (Symbol => "Hz", Second => -1, others => 0);



subtype Linear_Velocity_Type is Unit_Type 
	with Dimension => (Meter => 1, Second => -1, others => 0);

subtype Angular_Velocity_Type is Unit_Type
	with Dimension => (Degree => 1, Second => -1, others => 0);

subtype Linear_Acceleration_Type is Unit_Type 
	with Dimension => (Meter => 1, Second => -2, others => 0);

subtype Angular_Acceleration_Type is Unit_Type 
	with Dimension => (Degree => 1, Second => -2, others => 0);



CELSIUS_0 : constant Temperature_Type := Temperature_Type( 273.15 );

-- G : constant Linear_Acceleration_Type := 127137.6 * km/(hour ** 2); 
Meter : constant Length_Type := Length_Type(1.0);
Milli_Meter : constant Length_Type := 0.001 * Meter; 
km : constant Length_Type := 1000.0 * Meter;


Second : constant Time_Type := Time_Type ( 1.0 );
Milli_Second : constant Time_Type := 1.0e-3 * Second;
Micro_Second : constant Time_Type := 1.0e-6 * Second;

Degree : constant Angle_Type := Angle_Type ( 1.0 );


Pascal : constant Pressure_Type := Pressure_Type( 1.0 );
Bar    : constant Pressure_Type := Pressure_Type( 100_000.0 );

Kelvin : constant Temperature_Type := Temperature_Type( 1.0 );


-- converts Real_Time to Time_Type, precision is Nanosecond
function To_Time(rtime : Ada.Real_Time.Time) return Time_Type is
      ( Time_Type( Float ( (rtime - Ada.Real_Time.Time_First) / Ada.Real_Time.Nanoseconds(1) ) / 1.0e-9 ) );



end Units;
