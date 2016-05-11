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



with HIL.UART;

package body Logger --with SPARK_Mode 
is
	pragma SPARK_Mode;

	-- HAL, only change Adapter to port Code
	package body Adapter is
		procedure init(status : out Init_Error_Code) is
		begin
			HIL.UART.configure;
			status := SUCCESS;
		end init;


		procedure write(message : Message_Type) is
			--LF : Character := Character'Val(10);
			--CR : Character := Character'Val(13);
		begin
	 HIL.UART.write(HIL.UART.Console, HIL.UART.toData_Type ( message ) );
		end write;	
	end Adapter;


	-- internal states
	logger_level : Log_Level := DEBUG;


	procedure init(status : out Init_Error_Code) is
	begin
		Adapter.init(status);
	end init;


	function level_Message(level : Log_Level) return Message_Type is
	begin
		return (case level is
			when ERROR => "[E] ",		
			when WARN  => "[W] ",		
			when INFO  => "[I] ",	
			when DEBUG => "[D] ",
			when TRACE => "  > " );
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
