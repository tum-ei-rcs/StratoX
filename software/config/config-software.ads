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
   TEST_MODE_ACTIVE : constant Boolean := False;
   
   -------------
   --  Mission
   -------------
   
   CFG_GPS_LOCK_TIMEOUT : constant Units.Time_Type := 120.0 * Second;  
   --  when TEST_MODE_ACTIVE and that much time has passed, we continue even w/o GPS fix.   
   
   CFG_ASCEND_TIMEOUT : constant Units.Time_Type := 1800.0 * Second;     
   --  we unhitch unconditionally when that much time has passed since mission start (longbeep).
   --  Droptest: 600, Strato: 1800
   
   CFG_DESCEND_TIMEOUT : constant Units.Time_Type := 3600.0 * Second;   
   --  when TEST_MODE_ACTIVE and this much time has passed since unhitch,
   --  we unconditionally assume landed. Note that there is also a landing detection.
   --  Droptest: 360, Strato: 3600. Blockwalk: 360
   
   CFG_LANDED_STABLE_TIME : constant Units.Time_Type := 300.0 * Second;
   --  when that much time has passed during descent w/o movement, we assume landed.
   
   POSITION_LEAST_ACCURACY : constant Units.Length_Type := 20.0 * Meter; 
   --  the mission will not start unless the position estimate is at least that accurate
   --  the worst accepted accuracy for mission start
    
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
