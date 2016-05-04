-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Driver for the Barometer MS5611-01BA03
-- 
-- ToDo:
-- [ ] Adjustment to current System
-- [ ] Use HIL.I2C


with units;

package MS5611.Driver is

   type Device_Type is (Baro, NONE);
   
	type Error_Type is (SUCCESS, FAILURE);

   subtype Time_Type is units.Time_Type;
   
	subtype Temperature_Type is units.Temperature_Type range  233.15 ..    358.15;  -- -40° .. 85°
	subtype Pressure_Type    is units.Pressure_Type    range 1000.0  .. 120000.0;

	type OSR_Type is (
		OSR_256,
		OSR_512,
		OSR_1024,
		OSR_2048,
		OSR_4096
	);

        procedure reset;
	procedure init;
	procedure update_val;   -- call this periodically
	function get_temperature return Temperature_Type;
	function get_pressure return Pressure_Type;
	procedure self_check( Status : out Error_Type );


end MS5611.Driver;
