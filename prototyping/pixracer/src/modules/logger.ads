--  Project: Strato
--  System:  Stratosphere Ballon Flight Controller
--  Author: Emanuel Regnath (emanuel.regnath@tum.de)
--
--  Description:
--     allows logging of string messages at several logging levels.

--  Usage:
--     Logger.init  -- initializes the Logger
--     Logger.log(Logger.INFO, "Program started.")  -- writes log on info level
package Logger with SPARK_Mode
is
   type Log_Level is (SENSOR, ERROR, WARN, INFO, DEBUG, TRACE);

   type Init_Error_Code is (SUCCESS, ERROR);
   subtype Message_Type is String;

   procedure init (status : out Init_Error_Code);

   --  create a new log message
   procedure log (msg_level : Log_Level; message : Message_Type);

   procedure set_Log_Level (level : Log_Level);

   procedure Start_SDLog;
   --  start a new logfile on the SD card

private
   --  FIXME: documentation required
   package Adapter is
      procedure init (status : out Init_Error_Code);
      procedure write (message : Message_Type);
   end Adapter;

end Logger;
