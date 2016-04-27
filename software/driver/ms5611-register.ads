-- Project: MART - Modular Airborne Real-Time Testbed
-- System:  Emergency Recovery System
-- Authors: Markus Neumair (Original C-Code)
--          Emanuel Regnath (emanuel.regnath@tum.de) (Ada Port)
-- 
-- Module Description:
-- Driver for the Barometer MS5611-01BA03

-- 08152/93020
-- 

with Bit_Types; use Bit_Types;

private package MS5611.Register is

	type Command_Type is mod 2**8;

	-- Constants
	TEMP_HIGH     : constant := 20.0;
	TEMP_LOW      : constant := -15.0;


	--Address
	BAROMETER_ADR : constant := Unsigned_8(16#77#);  -- I2C-Address of the barometer

	-- Commands
	CMD_RESET    : constant Command_Type := 16#1E#; -- ADC reset command
	CMD_ADC_READ : constant Command_Type := 16#00#; -- ADC read command

   
	CMD_CONV_D1      : constant Command_Type := 16#40#;  -- Pressure conversion commands
 
	CMD_CONV_D1_256  : constant Command_Type := 16#40#;  -- Pressure conversion commands
	CMD_CONV_D1_512  : constant Command_Type := 16#42#;
	CMD_CONV_D1_1024 : constant Command_Type := 16#44#;
	CMD_CONV_D1_2048 : constant Command_Type := 16#46#;
	CMD_CONV_D1_4096 : constant Command_Type := 16#48#;

	CMD_CONV_D2      : constant Command_Type := 16#50#;  -- Pressure conversion commands

   
	CMD_CONV_D2_256  : constant Command_Type := 16#50#;  -- Temperature conversion commands
	CMD_CONV_D2_512  : constant Command_Type := 16#52#;
	CMD_CONV_D2_1024 : constant Command_Type := 16#54#;
	CMD_CONV_D2_2048 : constant Command_Type := 16#56#;
	CMD_CONV_D2_4096 : constant Command_Type := 16#58#;

	CMD_READ_C1  : constant Command_Type := 16#A2#; --*< Prom read command
	CMD_READ_C2  : constant Command_Type := 16#A4#; --*< Prom read command
	CMD_READ_C3  : constant Command_Type := 16#A6#; --*< Prom read command
	CMD_READ_C4  : constant Command_Type := 16#A8#; --*< Prom read command
	CMD_READ_C5  : constant Command_Type := 16#AA#; --*< Prom read command
	CMD_READ_C6  : constant Command_Type := 16#AC#; --*< Prom read command
	CMD_READ_CRC : constant Command_Type := 16#AE#; --*< Prom read command


end MS5611.Register;
