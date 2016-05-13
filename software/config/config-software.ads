-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
-- Module: Software Configuration
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description:
-- Configuration of the Software, adjust these parameters to your needs



with units;
with Logger;

package Config.Software is

	DEBUG_MODE_IS_ACTIVE : constant Boolean := True;

   CFG_LOGGER_LEVEL_UART : constant Logger.Log_Level := Logger.TRACE;


	-- Bus Timeouts
	I2C_READ_TIMEOUT : constant units.Time_Type := units.Time_Type( 10.0 );


	-- filter configuration


	-- PID configuration

	

end Config.Software;
