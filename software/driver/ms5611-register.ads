-- Project: MART - Modular Airborne Real-Time Testbed
-- System:  Emergency Recovery System
-- Authors: Markus Neumair (Original C-Code)
--          Emanuel Regnath (emanuel.regnath@tum.de) (Ada Port)
-- 
-- Module Description:
-- Driver for the Barometer MS5611-01BA03


private package MS5611.Registers is

	--Address
	BAROMETER_ADR : constant := Unsigned_8(16#77#)	;--*< TWI-Address of the barometer

	-- Commands
	CMD_RESET    : constant Byte := 16#1E#; --*< ADC reset command
	CMD_ADC_READ : constant Byte := 16#00#; --*< ADC read command
	CMD_ADC_CONV : constant Byte := 16#40#; --*< ADC conversion command
	REG_ADC_D1   : constant Register_Address_Type := 16#00#; --*< ADC D1 conversion
	REG_ADC_D2   : constant Register_Address_Type := 16#10#; --*< ADC D2 conversion
	REG_ADC_256  : constant Register_Address_Type := 16#00#; --*< ADC OSR:=256
	REG_ADC_512  : constant Register_Address_Type := 16#02#; --*< ADC OSR:=512
	REG_ADC1_024 : constant Register_Address_Type := 16#04#; --*< ADC OSR:1_024
	REG_ADC2_048 : constant Register_Address_Type := 16#06#; --*< ADC OSR:2_048
	REG_ADC4_096 : constant Register_Address_Type := 16#08#; --*< ADC OSR:4_096
	CMD_PROM_RD  : constant Register_Address_Type := 16#A0#; --*< Prom read command

	CMD_READ_C1  : constant Register_Address_Type := 16#A2#; --*< Prom read command
	CMD_READ_C2  : constant Register_Address_Type := 16#A4#; --*< Prom read command
	CMD_READ_C3  : constant Register_Address_Type := 16#A6#; --*< Prom read command
	CMD_READ_C4  : constant Register_Address_Type := 16#A8#; --*< Prom read command
	CMD_READ_C5  : constant Register_Address_Type := 16#AA#; --*< Prom read command
	CMD_READ_C6  : constant Register_Address_Type := 16#AC#; --*< Prom read command
	CMD_READ_CRC : constant Register_Address_Type := 16#AE#; --*< Prom read command


end MS5611.Registers;
