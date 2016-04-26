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



package MS5611.Driver is

	function init return Init_Error_Code;
	function update_val return Sample_Status_Type;
	function get_temperature return CentiCelsius;
	function get_pressure return Integer_32;
	function self_check return Self_Check_Status;

private:
	subtype Data_Array is array (Positive range <>) of Byte;
	procedure writeToDevice(data : in Data_Array);

end MS5611.Driver;
