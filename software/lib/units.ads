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
	with Dimension => (Symbol => 'A', Ampere => 1, others => 0);

subtype Angle_Type is Unit_Type 
	with Dimension => (Symbol => "deg", Degree => -1, others => 0);


-- Derived Units
subtype Pressure_Type is Unit_Type 
	with Dimension => (Symbol = "Pa", Kilogram => 1, Meter => -1, Second => -2, others => 0);

subtype Voltage_Type is Unit_Type
	with Dimension => (Symbol = 'V', Meter => 2, Kilogram => 1, Second => -3, Ampere => -1, others => 0);

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





-- G : constant Linear_Acceleration_Type := 127137.6 * km/(hour ** 2); 
m : constant Length_Type := Lenth_Type(1.0);
mm : constant Length_Type := 0.001 * m; 
km : constant Length_Type := 1000.0 * m;


end Units;