-- Project: Strato
-- System:  Stratosphere Ballon Flight Controller
-- Author: Emanuel Regnath (emanuel.regnath@tum.de)
-- 
-- Description: 
--     allows logging of string messages at several logging levels. Easy porting 
--     to different hardware, only change the adapter methods. 
--
-- Usage: 
--     Logger.init  -- initializes the Logger
--     Logger.log(Logger.INFO, "Program started.")  -- writes log on info level
with ULog;

-- ToDo: Unconstrained Strings require a secondary stack for each call... can this be optimized?
package Logger with SPARK_Mode,  
  Abstract_State => (LogState with External)
  -- we need a state here because log() needs Global aspect
  -- since protected object is part of the state, and p.o. is
  -- by definition synchronous and synchronous objects (?) are
  -- by definition external, we need to mark it as such
is
   -- parameters of this package
   QUEUE_LENGTH : constant Positive := 10; -- TODO: show by schedulability analysis that this is enough
	      
   type Init_Error_Code is (SUCCESS, ERROR);
   subtype Message_Type is String;
   type Log_Level is (SENSOR, ERROR, WARN, INFO, DEBUG, TRACE);

   procedure init(status : out Init_Error_Code);

   -- create a new log message
   procedure log(level : Log_Level; message : Message_Type);
--     Global => State,
   -- Global => logger_level,
--     Pre => message /= " ";
--pragma Assertion_Policy (Pre => Check);

   procedure log_ulog(level : Log_Level; msg : ULog.Message'Class);

   -- adjust the minimum level that is kept. messages below that
   -- level are discarded silently.
   procedure set_Log_Level(level : Log_Level);
           
private
   -- FIXME: documentation required
   package Adapter is
      procedure init(status : out Init_Error_Code);
      procedure write(message : Message_Type);
   end Adapter;              
   
end Logger;
