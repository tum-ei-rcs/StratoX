-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Software Configuration
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description:
-- Configuration of the Software, adjust these parameters to your needs

with Units;
with Logger;

package Config.Software is

   DEBUG_MODE_IS_ACTIVE : constant Boolean := True;

   CFG_LOGGER_LEVEL_UART : constant Logger.Log_Level := Logger.DEBUG;

   MAIN_TICK_RATE_MS : constant := 40;   -- Tickrate in Milliseconds

   -- PX4IO Timeout RC  : 2000ms
   -- PX4IO Timeout FMU (no controls) : 500ms

   -- Bus Timeouts
   I2C_READ_TIMEOUT : constant Units.Time_Type := Units.Time_Type (10.0);

   -- filter configuration

   -- PID configuration

   -- MPU6000
   MPU6000_SAMPLE_RATE_HZ : constant := 100;
   
   
   -- PX4IO
   PX4IO_BAUD_RATE_HZ : constant := 1_500_000;
   
   
   -- UBLOX-
   UBLOX_BAUD_RATE_HZ : constant := 38_400;
   
   
   
   

end Config.Software;
