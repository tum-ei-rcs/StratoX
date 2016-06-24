-- Project: MART - Modular Airborne Real-Time Testbed
-- System:  Emergency Recovery System
-- Authors: Markus Neumair (Original C-Code)
--          Emanuel Regnath (emanuel.regnath@tum.de) (Ada Port)
-- 
-- Module Description:
-- Driver for the Barometer MS5611-01BA03



private package MS5611.Register is

   type Command_Type is mod 2**8;

   -- Constants
   TEMP_HIGH     : constant := 20.0;
   TEMP_LOW      : constant := -15.0;

   -- SPI Address of chip
   BAROMETER_ADR : constant := 16#77#;  -- I2C-Address of the barometer

   -- Commands
   CMD_RESET        : constant Command_Type := 16#1E#; -- ADC reset command
   CMD_ADC_READ     : constant Command_Type := 16#00#; -- ADC read command

   CMD_D1_CONV_256  : constant Command_Type := 16#40#;  -- Pressure Conversion commands
   CMD_D1_CONV_512  : constant Command_Type := 16#42#;
   CMD_D1_CONV_1024 : constant Command_Type := 16#44#;
   CMD_D1_CONV_2048 : constant Command_Type := 16#46#;
   CMD_D1_CONV_4096 : constant Command_Type := 16#48#;

   CMD_D2_CONV_256  : constant Command_Type := 16#50#;  -- Temperature Conversion commands
   CMD_D2_CONV_512  : constant Command_Type := 16#52#;
   CMD_D2_CONV_1024 : constant Command_Type := 16#54#;
   CMD_D2_CONV_2048 : constant Command_Type := 16#56#;
   CMD_D2_CONV_4096 : constant Command_Type := 16#58#;

   CMD_READ_C1      : constant Command_Type := 16#A2#; -- C1 read command
   CMD_READ_C2      : constant Command_Type := 16#A4#; -- C2
   CMD_READ_C3      : constant Command_Type := 16#A6#; -- C3
   CMD_READ_C4      : constant Command_Type := 16#A8#; -- C4
   CMD_READ_C5      : constant Command_Type := 16#AA#; -- C5
   CMD_READ_C6      : constant Command_Type := 16#AC#; -- C6
   CMD_READ_CRC     : constant Command_Type := 16#AE#; -- CRC

end MS5611.Register;
