--  Project: StratoX
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--           Martin Becker (becker@rcs.ei.tum.de)
--
--  Description:
--     allows logging of structured messages at several logging levels.
--
--  Usage:
--     Logger.init  -- initializes the Logger
--     Logger.log_console (Logger.INFO, "Program started.")  -- writes to console
--     Logger.log_sd (Logger.INFO, gps_msg) -- writes GPS record to SD card
with ULog;

--  @summary Simultaneously writes to UART, and SD card.
--  Write to SD card is done via a queue and a background task,
--  becauuse it can be slow.
package Logger with SPARK_Mode,
  Abstract_State => (LogState with External)
  --  we need a state here because log() needs Global aspect
  --  since protected object is part of the state, and p.o. is
  --  by definition synchronous and synchronous objects are
  --  by definition external, we need to mark it as such
is
   type Init_Error_Code is (SUCCESS, ERROR);
   subtype Message_Type is String;
   type Log_Level is (SENSOR, ERROR, WARN, INFO, DEBUG, TRACE);

   procedure Init (status : out Init_Error_Code);

   procedure log (msg_level : Log_Level; message : Message_Type);
   --  wrapper for log_console

   procedure log_console (msg_level : Log_Level; message : Message_Type);
   --  write a new text log message (shown on console, logged to SD)

   procedure log_sd (msg_level : Log_Level; message : ULog.Message);
   --  write a new ulog message (not shown on console, logged to SD)

   procedure Set_Log_Level (level : Log_Level);

   procedure Start_SDLog;
   --  start a new logfile on the SD card

   LOG_QUEUE_LENGTH : constant := 20;

private
   --  FIXME: documentation required
   package Adapter is
      procedure init_adapter (status : out Init_Error_Code);
      procedure write (message : Message_Type);
   end Adapter;

end Logger;
