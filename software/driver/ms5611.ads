-- Project: MART - Modular Airborne Real-Time Testbed
-- System:  Emergency Recovery System
-- Authors: Markus Neumair (Original C-Code)
--          Emanuel Regnath (emanuel.regnath@tum.de) (Ada Port)
-- 
-- Module Description:
-- Driver for the Barometer MS5611-01BA03


package MS5611 is

	--Address
	BAROMETER_ADR : constant := 16#77# ;--*< TWI-Address of the barometer


	type Register_Address_Type is mod 2**8;

	type Init_Error_Code is (SUCCESS, INITIALIZING, ERROR);
	type Self_Check_Status is (CHECKING, CHECKING_DONE);

	subtype CentiCelsius is Integer_32 range -4000 .. 8500;
	subtype Pascal is Integer_32 range 1000 .. 120000;

	-- define return values 
	type Sample_Status_Type is (
			BARO_NO_NEW_VALUE, 
			BARO_NEW_TEMPERATURE, 
			BARO_NEW_PRESSURE, 
			BARO_READ_TEMPERATURE_ERROR, 
			BARO_READ_PRESSURE_ERROR
		);
	

	DELTA_CNT_BAROMETER_LIMIT : constant := Unsigned_8(7); --< Maximum time, critical descend-rates are tolerated: 
			-- DElTA_CNT_MAX*20ms:=140ms with too high descend rate


end MS5611;
