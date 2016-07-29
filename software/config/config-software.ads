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
   
   CFG_IN_AIR_RESTART : constant Boolean := False;
   
   
   
   -- Misison
   CFG_GPS_LOCK_TIMEOUT : constant Units.Time_Type := 30.0 * Second;
   CFG_ASCEND_TIMEOUT : constant Units.Time_Type := 20.0 * Second;
   CFG_DESCEND_TIMEOUT : constant Units.Time_Type := 90.0 * Second;
   
   

   -- CFG_GPS_BAUDRATE : constant Frequency_Type := 9600.0 * Hertz;


   CFG_LOGGER_LEVEL_UART : constant Logger.Log_Level := Logger.DEBUG;
   CFG_LOGGER_CALL_SKIP: constant := 20;
   

   MAIN_TICK_RATE_MS : constant := 20;   -- Tickrate in Milliseconds

   -- PX4IO Timeout RC  : 2000ms
   -- PX4IO Timeout FMU (no controls) : 500ms

   -- Bus Timeouts
   I2C_READ_TIMEOUT : constant Units.Time_Type := 1.0 * Milli * Second;
   UART_READ_TIMEOUT : constant Units.Time_Type := 1.0 * Milli * Second;

   -- filter configuration



         
   
   -- PID Controller
   CFG_PID_PITCH_P : constant := 0.550;
   CFG_PID_PITCH_I : constant := 0.040;
   CFG_PID_PITCH_D : constant := 0.005;
   
   CFG_PID_ROLL_P : constant := 0.450;
   CFG_PID_ROLL_I : constant := 0.060;
   CFG_PID_ROLL_D : constant := 0.020;

   CFG_PID_YAW_P : constant := 0.070;  -- 0.020 gut
   CFG_PID_YAW_I : constant := 0.050;
   CFG_PID_YAW_D : constant := 0.000;
   

end Config.Software;
