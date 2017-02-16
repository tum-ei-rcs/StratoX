with Units;
with Logger;

package config.software is

   CSV_SEP : Character := ';';

   DEBUG_MODE_IS_ACTIVE : constant Boolean := True;     
   MAIN_TICK_RATE_MS : constant := 20;   -- Tickrate in Milliseconds
   TEST_MODE_ACTIVE : constant Boolean := False;
   
   --  Mission
   CFG_ASCEND_TIMEOUT : constant Units.Time_Type := 1800.0 * Second;     
   --  after this much time since mission start we unhitch. 
   --  Droptest: 600, Strato: 1800
   
   CFG_DESCEND_TIMEOUT : constant Units.Time_Type := 1800.0 * Second;   
   --  after this much time since unhitch we assume landed
   --  Droptest: 360, Strato: 1800. Blockwalk: 360
   
   POSITION_LEAST_ACCURACY : constant Units.Length_Type := 20.0 * Meter; 
   --  the worst accepted GPS position accuracy for mission start
    
   CFG_LOGGER_LEVEL_UART : constant Logger.Log_Level := Logger.DEBUG;
   CFG_LOGGER_CALL_SKIP: constant := 10;  -- prescaler...only every nth message is printed
      

   

end Config.Software;
