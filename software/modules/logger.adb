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
   type Buffer_T is array (Natural range <>) of Log_Msg;
   type bufpos is mod QUEUE_LENGTH;
         
   -- protected type to implement the buffer
   protected type Msg_Queue_T is  
      procedure New_Msg (msg : in  Log_Msg);        
      -- enqueue new message. this is not blocking, except to ensure mutex.
      -- can silently fail if buffer is full
      -- FIXME: how can we specify a precondition on the private variable?
      -- for now we put an assertion in the body
      
      entry Get_Msg (msg : out Log_Msg);
      --  with Pre => Num_Queued > 0;
      -- try to get new message from buffer. if empty, this is blocking 
      -- until buffer has data, and then returns it.
      -- FIXME: how can we specify a precondition on the private variable?
      -- for now we put an assertion in the body
      
      function Get_Num_Overflows return Natural;
      -- query how often the buffer overflowed. If this happens, either increase
      -- the buffer QUEUE_LENGTH, or increase priority of the logger task.
      
      function Get_Length return Natural;
      -- query number of messages waiting in the logging queue.
   private
      Buffer : Buffer_T (0 .. QUEUE_LENGTH - 1); 
      -- cannot use a discriminant for this (would violate No_Implicit_Heap_Allocations)

      Num_Queued : Natural := 0;
      Not_Empty : Boolean := false; -- simple barrier (Ravenscar)
      Pos_Read : bufpos := 0;
      Pos_Write : bufpos := 0;
      Overflows : Natural := 0;
      -- cannot use a dynamic predicate to etablish relationship, because this requires
      -- a record. But we cannot have a record, since this would make Not_Empty a
      -- non-simple barrier (=> Ravenscar violation).
   end Msg_Queue_T;   
   
   protected body Msg_Queue_T is       
      procedure New_Msg ( msg : in  Log_Msg ) is 
      begin
         if (msg.valid) then         
            Buffer ( Integer (Pos_Write)) := msg;
            Pos_Write := Pos_Write + 1;
            if (Num_Queued < Buffer'Last) then               
               Num_Queued := Num_Queued + 1;    
            else -- =Buffer'Last
               Pos_Read := Pos_Read + 1; -- overwrite oldest
               if (Overflows < Natural'Last) then
                  Overflows := Overflows + 1;
               end if;
            end if;
         end if;
         
         Not_Empty := (Num_Queued > 0);
         pragma Assert ( (Not_Empty and (Num_Queued > 0)) or ((not Not_Empty) and (Num_Queued = 0)) );
      end New_Msg;
      
      entry Get_Msg ( msg : out Log_Msg ) when Not_Empty is      
      begin
         pragma Assume ( Num_Queued > 0); -- via barrier and assert in New_Msg
                  
         msg := Buffer (Integer (Pos_Read));
         Pos_Read := Pos_Read + 1;
         Num_Queued := Num_Queued - 1;

         Not_Empty := Num_Queued > 0;
         pragma Assert ( (Not_Empty and (Num_Queued > 0)) or ((not Not_Empty) and (Num_Queued = 0)) );
      end Get_Msg;      
      
      function Get_Num_Overflows return Natural is
      begin
         return Overflows;
      end Get_Num_Overflows;
      
      function Get_Length return Natural is
      begin
         return Num_Queued;
      end Get_Length;
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
