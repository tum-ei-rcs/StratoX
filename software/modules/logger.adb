-- Project: MART - Modular Airborne Real-Time Testbed
-- System:  Emergency Recovery System
-- Author: Emanuel Regnath (emanuel.regnath@tum.de)
-- 
-- Description: 
--     allows logging of structured messages at several logging levels. 
--     Simultaneously writes to UART, to SD card and to data link (TODO).
--
-- Usage: 
--     Logger.init  -- initializes the Logger
--     Logger.log(Logger.INFO, "Program started.")  -- writes log on info level

with System;
with HIL.UART;
with SDMemory;
with ULog.GPS;
with HIL.Devices;

package body Logger with SPARK_Mode,
  Refined_State => (LogState => (queue, Logging_Task, logger_level, msg_gps))
is  
    
   -- the type for the queue buffer
   type Buffer_T is array (Natural range <>) of ULog.Message;
   type bufpos is mod QUEUE_LENGTH;
   
   -- if GNATprove crashes with reference to that file,
   -- then you have run into bug KP-160-P601-005.
   -- workaround: move decl of protected type to package spec.
   
   -- protected type to implement the buffer
   protected type Msg_Queue_T is  
      procedure New_Msg (msg : in ULog.Message);      
      -- enqueue new message. this is not blocking, except to ensure mutex.
      -- can silently fail if buffer is full
      -- FIXME: how can we specify a precondition on the private variable?
      -- for now we put an assertion in the body     
      
      entry Get_Msg (msg : out ULog.Message);
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
      Not_Empty : Boolean := False; -- simple barrier (Ravenscar)
      Pos_Read : bufpos := 0;
      Pos_Write : bufpos := 0;
      Num_Overflows : Natural := 0;
      -- cannot use a dynamic predicate to etablish relationship, because this requires
      -- a record. But we cannot have a record, since this would make Not_Empty a
      -- non-simple barrier (=> Ravenscar violation).
   end Msg_Queue_T; 
      
   -- sporadic logging task waking up when message is enqueued
   task Logging_Task is
      pragma Priority (System.Priority'First); -- lowest prio for logging
   end Logging_Task;
   
   ----------------------------
   --  Instatiation / Body   --
   ----------------------------
   
   -- internal states
   queue        : Msg_Queue_T;  
   logger_level : Log_Level := DEBUG;
   
   -- test (remove...just for sake of "with"ing ULog.GPS and keeping SPARK happy
   msg_gps : ULog.GPS.Message;

   -- the task which logs to SD card in the background
   task body Logging_Task is 
      msg : ULog.Message;
      BUFLEN : constant := 1024;
      bytes : HIL.Byte_Array (1 .. BUFLEN);
   begin     
      ULog.Get_Header (bytes); -- possibly in chunks, because it's describing all messages
      --  TODO: start new file, write header
      --  sdmemory.write(bytes);
      loop
         queue.Get_Msg (msg);
         
         -- TODO: write to SD card and forward to radio link
         null; 
         ULog.Serialize (msg, bytes); -- FIXME: how to ensure enough buffer?
         --sdmemory.write(bytes);                  

         -- TODO: occasionally log queue state (overflows, num_queued).
      end loop;
   end Logging_Task;   
      
   -- implementation of the message queue
   protected body Msg_Queue_T is       
      procedure New_Msg (msg : in ULog.Message) is 
      begin

         Buffer ( Integer (Pos_Write)) := msg;
         Pos_Write := Pos_Write + 1;
         if Num_Queued < Buffer'Last then               
            Num_Queued := Num_Queued + 1;    
         else -- =Buffer'Last
            Pos_Read := Pos_Read + 1; -- overwrite oldest
            if Num_Overflows < Natural'Last then
               Num_Overflows := Num_Overflows + 1;
            end if;
         end if;
         
         Not_Empty := (Num_Queued > 0);
         pragma Assert ( (Not_Empty and (Num_Queued > 0)) or ((not Not_Empty) and (Num_Queued = 0)) );
      end New_Msg;
      
      entry Get_Msg (msg : out ULog.Message) when Not_Empty is      
      begin
         pragma Assume ( Num_Queued > 0); -- via barrier and assert in New_Msg
                  
         msg := Buffer (Integer (Pos_Read));
         Pos_Read := Pos_Read + 1;
         Num_Queued := Num_Queued - 1;

         Not_Empty := Num_Queued > 0;
         pragma Assert ( (Not_Empty and (Num_Queued > 0)) or ((not Not_Empty) and (Num_Queued = 0)) );
      end Get_Msg;      
      
      function Get_Num_Overflows return Natural is (Num_Overflows);      
      function Get_Length return Natural is (Num_Queued);
   end Msg_Queue_T;
      
   
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
         HIL.UART.write(HIL.Devices.Console, HIL.UART.toData_Type ( message & CR ) );
      end write;	
   end Adapter;

   procedure init(status : out Init_Error_Code) is
   begin
      Adapter.init(status);
      SDMemory.Init;
   end init;
   
   function Image (level : Log_Level) return String is 
   begin
      return (case level is
                 when SENSOR => "S: ",
                 when ERROR => "E: ",		
                 when WARN  => "W: ",		
                 when INFO  => "I: ",	
                 when DEBUG => "D: ",
                 when TRACE => "  > "
             );
   end Image;
          
   procedure log_ulog(level : Log_Level; msg : ULog.Message'Class) is
   begin
      if Log_Level'Pos(level) <= Log_Level'Pos(logger_level) then
         queue.New_Msg (ULog.Message (msg)); -- view conversion
      end if;
   end log_ulog;
   
   procedure log(level : Log_Level; message : Message_Type) 
   is      
   begin
      if Log_Level'Pos(level) <= Log_Level'Pos(logger_level) then
         Adapter.write(Log_Level'Image (level) & message);
      end if;      
   end log;

   procedure set_Log_Level(level : Log_Level) is
   begin
      logger_level := level;
   end set_Log_Level;

end Logger;
