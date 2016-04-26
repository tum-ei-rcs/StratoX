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

package Config.Software is

	DEBUG_MODE_IS_ACTIVE : constant Boolean := True;

	CPU_CLOCK_HZ : constant Integer := 168_000_000;


	-- Bus Timeouts
	I2C_READ_TIMEOUT : constant units.Time_Type := 10.0;


	-- filter configuration


	-- PID configuration

	

end Config.Software;