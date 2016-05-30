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


with System;
with HIL.UART;
with SDIO.Driver;

package body Logger with SPARK_Mode 
is
   -- one message object
   type Log_Msg is
       record
          valid : Boolean := False;
          level : Log_Level := TRACE;
          -- TODO
       end record;
   
   -- the type for the queue buffer
   type Buffer_T is array (positive range <>) of Log_Msg;
      
   -- protected type to implement the buffer
   protected type Msg_Queue_T is    
      procedure New_Msg (msg : in  Log_Msg);
      -- enqueue new message. this is not blocking, except to ensure mutex.
      -- can silently fail if buffer is full
      
      entry Get_Msg (msg : out Log_Msg);
      -- try to get new message from buffer. if empty, this is blocking 
      -- until buffer has data, and then returns it.
   private
      Buffer : Buffer_T (1 .. QUEUE_LENGTH); 
      -- cannot use a discriminant for this (would violate No_Implicit_Heap_Allocations)
      
      Not_Empty : Boolean := false;
      Num_Queued : Natural := 0;
   end Msg_Queue_T;   
   
   protected body Msg_Queue_T is       
      procedure New_Msg ( msg : in  Log_Msg ) is 
      begin         
         if (msg.valid and Num_Queued < Buffer'Last) then               
            Num_Queued := Num_Queued + 1;
            Buffer (Num_Queued) := msg;
            Not_Empty := true;
         end if;
      end New_Msg;
      
      entry Get_Msg ( msg : out Log_Msg ) when Not_Empty is
      begin
         msg := Buffer (Num_Queued); -- TODO: take oldest, not newest
         Num_Queued := Num_Queued - 1;
         if (Num_Queued = 0) then
            Not_Empty := false;
         end if;
      end Get_Msg;        
   end Msg_Queue_T;
   
   -- internal states
   logger_level : Log_Level := DEBUG;
   queue : Msg_Queue_T;
   
   -- sporadic logging task waiting for non-empty queue
   task Logging_Task is
      pragma Priority (System.Priority'First); -- lowest prio for logging
   end Logging_Task;
   task body Logging_Task is 
      msg : Log_Msg;
   begin
      loop
         queue.Get_Msg (msg);
         if (msg.valid) then
            null; -- TODO: write to SD card and forward to radio link
         end if;
         -- TODO: enorce minimum inter-arrival time?
      end loop;
   end Logging_Task;   
   
   -- HAL, only change Adapter to port Code
   package body Adapter is
      procedure init(status : out Init_Error_Code) is
      begin
         HIL.UART.configure;
         status := SUCCESS;
      end init;

      procedure write(message : Message_Type) is
         --LF : Character := Character'Val(10);
         CR : constant Character := Character'Val(13);  -- ASCII
      begin
         HIL.UART.write(HIL.UART.Console, HIL.UART.toData_Type ( message & CR ) );
      end write;	
   end Adapter;

   procedure init(status : out Init_Error_Code) is
   begin
      Adapter.init(status);
   end init;

   -- FIXME: re-write as Image(level : Log_Level)
   function Image (level : Log_Level) return String is 
   begin
      return (case level is
                 when ERROR => "E: ",		
                 when WARN  => "W: ",		
                 when INFO  => "I: ",	
                 when DEBUG => "D: ",
                 when TRACE => "  > ",
                 when others => ""
             );
   end Image;
          
   procedure log(level : Log_Level; message : Message_Type) is
      msg : constant Log_Msg := (level => level, valid => true);
   begin
      if Log_Level'Pos(level) <= Log_Level'Pos(logger_level) then
         Adapter.write(Log_Level'Image (level) & message);
      end if;
      queue.New_Msg(msg);
   end log;

   procedure set_Log_Level(level : Log_Level) is
   begin
      logger_level := level;
   end set_Log_Level;

end Logger;
