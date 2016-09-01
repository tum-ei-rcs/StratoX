-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Software Configuration
-- Authors:     Emanuel Regnath (emanuel.regnath@tum.de)
-- 
with Units;
with Logger;

--  @summary Configuration of the Software, adjust these parameters to your needs
package Config.Software with SPARK_Mode is

   DEBUG_MODE_IS_ACTIVE : constant Boolean := True;     
   MAIN_TICK_RATE_MS : constant := 20;   -- Tickrate in Milliseconds
   TEST_MODE_ACTIVE : constant Boolean := True;
   
   -- Misison
   CFG_GPS_LOCK_TIMEOUT : constant Units.Time_Type := 120.0 * Second;  -- Droptest: 120, Strato: TBD
   CFG_ASCEND_TIMEOUT : constant Units.Time_Type := 1800.0 * Second;     -- Droptest: 600, Strato: 30m
   CFG_DESCEND_TIMEOUT : constant Units.Time_Type := 1800.0 * Second;   -- Droptest: 360, Strato: 30m
   
    
   CFG_LOGGER_LEVEL_UART : constant Logger.Log_Level := Logger.DEBUG;
   CFG_LOGGER_CALL_SKIP: constant := 10;  -- prescaler...only every nth message is printed
      

   -- PX4IO Timeout RC  : 2000ms
   -- PX4IO Timeout FMU (no controls) : 500ms

   -- Bus Timeouts
   I2C_READ_TIMEOUT : constant Units.Time_Type := 1.0 * Milli * Second;
   UART_READ_TIMEOUT : constant Units.Time_Type := 1.0 * Milli * Second;

   -- filter configuration



         
   
   -- PID Controller
   -- ----------------------------------------

   CFG_CONTROLL_UNSTABLE_PITCH_THRESHOLD : constant Pitch_Type := 40.0*Degree;
   CFG_CONTROLL_UNSTABLE_ROLL_THRESHOLD : constant Roll_Type := 40.0*Degree;
   
   
   
   -- PID Gains
   CFG_PID_PITCH_P : constant := 0.550;
   CFG_PID_PITCH_I : constant := 0.040;
   CFG_PID_PITCH_D : constant := 0.020;
   
   CFG_PID_ROLL_P : constant := 0.450;
   CFG_PID_ROLL_I : constant := 0.060;
   CFG_PID_ROLL_D : constant := 0.020;

   CFG_PID_YAW_P : constant := 0.050;  -- error 60° => 3° target roll
   CFG_PID_YAW_I : constant := 0.030;  -- error 60° for 3s => 6° target roll
   CFG_PID_YAW_D : constant := 0.000;
   

end Config.Software;
