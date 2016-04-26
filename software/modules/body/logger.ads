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

with AVR.Strings; use AVR.Strings;

package Logger --with SPARK_Mode 
is
	
	type Init_Error_Code is (SUCCESS, ERROR);

	subtype Message_Type is AVR.Strings.AVR_String;
	type Log_Level is (ERROR, WARN, INFO, DEBUG, TRACE);

	function init return Init_Error_Code;

	procedure log(level : Log_Level; message : Message_Type) with
		-- Global => logger_level,
		Pre => message /= " ";
		--pragma Assertion_Policy (Pre => Check);

	procedure set_Log_Level(level : Log_Level);

private
	package Adapter is
		function init return Init_Error_Code;
		procedure write(message : Message_Type);
	end Adapter;
end Logger;