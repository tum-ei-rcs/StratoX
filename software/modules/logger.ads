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


-- ToDo: Unconstrained Strings require a secondary stack for each call... can this be optimized?

package Logger with SPARK_Mode 
is
	
	type Init_Error_Code is (SUCCESS, ERROR);

	subtype Message_Type is String;
	type Log_Level is (ERROR, WARN, INFO, DEBUG, TRACE);

	procedure init(status : out Init_Error_Code);

	procedure log(level : Log_Level; message : Message_Type) with
		-- Global => logger_level,
		Pre => message /= " ";
		--pragma Assertion_Policy (Pre => Check);

	procedure set_Log_Level(level : Log_Level);

-- TODO: separate task for SDIO logging, reading from a buffer. Because SDIO is slow.
private
	package Adapter is
		procedure init(status : out Init_Error_Code);
		procedure write(message : Message_Type);
	end Adapter;
end Logger;
