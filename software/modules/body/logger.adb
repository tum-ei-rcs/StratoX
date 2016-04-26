-- Project: MART - Modular Airborne Real-Time Testbed
-- System:  Emergency Recovery System
-- Author: Emanuel Regnath (emanuel.regnath@tum.de)
-- 
-- Description: 
--     allows logging of string messages at several logging levels. Easy porting 
--     to different hardware, only change the adapter methods. 
--
-- Usage: 
--     Logger.init  -- initializes the Logger
--     Logger.log(Logger.INFO, "Program started.")  -- writes log on info level


with AVR; use AVR;
--with AVR.Strings;                  use AVR.Strings;
--with AVR.UART;	-- required by Adapter (Hardware Abstraction Layer)
with uart;
	use type uart.Init_Error_Code;

package body Logger --with SPARK_Mode 
is
	pragma SPARK_Mode;

	-- HAL, only change Adapter to port Code
	package body Adapter is
		function init return Init_Error_Code is			
		begin
			-- UART.Init(51);
			-- return SUCCESS;
			if uart.init = uart.SUCCESS then
				return SUCCESS;
			else 
				return ERROR;
			end if;
			
		end init;


		procedure write(message : Message_Type) is
			--LF : Character := Character'Val(10);
			--CR : Character := Character'Val(13);
		begin
			uart.putline(message);
			-- UART.Put(AVR_String(message));
			-- UART.Put(CR);
			-- UART.Put(LF);
		end write;	
	end Adapter;


	-- internal states
	logger_level : Log_Level := DEBUG;


	function init return Init_Error_Code is
	begin
		return Adapter.init;
	end init;


	function level_Message(level : Log_Level) return Message_Type is
	begin
		case level is
			when ERROR =>
				return "[E] ";		
			when WARN =>
				return "[W] ";		
			when INFO =>
				return " ";	
			when DEBUG =>
				return "  >";
			when TRACE =>
				return "   '";
		end case;
	end level_Message;


	procedure log(level : Log_Level; message : Message_Type) is
	begin
		if Log_Level'Pos(level) <= Log_Level'Pos(logger_level) then
			Adapter.write(level_Message(level) & message);
		end if;
	end log;


	procedure set_Log_Level(level : Log_Level) is
	begin
		logger_level := level;
	end set_Log_Level;

end Logger;