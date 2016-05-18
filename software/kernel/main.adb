
-- Description:
-- Main System File
-- todo: better unit name

with CPU;
with Ada.Real_Time; use Ada.Real_Time;
with led_manager;
with MS5611.Driver;
with PX4IO.Driver;
with HIL.UART;
with HIL.SPI;
with Logger;
with Config.Software; use Config.Software;

package body Main is

--  	-- the mission can only go forward
--  	type Mission_State_Type is (
--  		UNKNOWN,
--  		INITIALIZING,
--  		SELF_TESTING,
--  		READY_TO_START,
--  		ASCENDING,
--  		HOLDING,
--  		DESCENDING,
--  		LANDED,
--  		FOUND,
--  		EVALUATING
--  	);
--  
--  
--  	type Mission_Event_Type is (
--  		UNKNOWN,
--  		INITIALIZATION_START,
--  		INITIALIZATION_END,
--  		SELF_TEST_START,
--  		SELF_TEST_END,
--  		ARMED,
--  		RELEASED,
--  		BALLOON_CUT,
--  		DESCENDING,
--  		LANDED,
--  		FOUND,
--  		EVALUATED
--  	);
--  
--  
--  	type Health_Status_Type is (
--  		UNKNOWN,
--  		OK,
--  		EMERGENCY
--  	);
--  
--  	type Altitude_State_Type is (
--  		GROUND,
--  		ASCENDING,
--  		STABLE,
--  		DESCENDING,
--  		FREEFALL
--  	);
--  
--  
--  	type System_State_Type is record
--  		Mission_State : Mission_State_Type := UNKNOWN;
--  		Health_Status : Health_Status_Type := UNKNOWN;	
--  	end record;

	procedure initialize is
	begin
      CPU.initialize;
      
      Logger.set_Log_Level(CFG_LOGGER_LEVEL_UART);
      perform_Self_Test;
      
      MS5611.Driver.reset;
      
      -- wait to satisfy some timing
      delay until Clock + Milliseconds (5);
      MS5611.Driver.init;
      PX4IO.Driver.initialize;
	end initialize;


   procedure perform_Self_Test is
   begin
      Logger.log(Logger.INFO, "Starting Self Test");
      
      Logger.log(Logger.DEBUG, "Logger: Debug Test Message");
      Logger.log(Logger.TRACE, "Logger: Trace Test Message");
      
      PX4IO.Driver.initialize;
      
   end perform_Self_Test;


   procedure run_Loop is
       data : HIL.SPI.Data_Type(1 .. 3) := (others => 0);
       data_rx : HIL.UART.Data_Type(1 .. 1) := (others => 0);
       msg : String := "Main";
   begin
      led_manager.LED_blink(led_manager.SLOW);
      
      Logger.log(Logger.INFO, msg);
      loop
	 delay until Clock + Milliseconds (200);
	 led_manager.LED_tick(200);
	 led_manager.LED_sync;
         
         -- UART Test
         HIL.UART.write(HIL.UART.Console, (70, 65) );
         HIL.UART.read(HIL.UART.Console, data_rx);
         
         case ( Character'Val( data_rx(1) ) ) is
         when 't' => perform_Self_Test;
         when 's' => PX4IO.Driver.read_Status;
         when 'l' => led_manager.LED_blink(led_manager.FAST);
         when others   => null;
         end case;
         
         
         
         -- MS5611 Test
         MS5611.Driver.update_val;
         
         -- SPI Test
         HIL.SPI.select_Chip(HIL.SPI.Extern);
         HIL.SPI.transfer(HIL.SPI.Extern, (166, 0, 0), data );
         HIL.SPI.deselect_Chip(HIL.SPI.Extern);
         
      end loop;
   end run_Loop;	

end Main;
