--  Project: StratoX
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--          Martin Becker (becker@rcs.ei.tum.de)
--
--  Description:
--     allows logging of structured messages at several logging levels.
--
--  Usage:
--     Logger.init  -- initializes the Logger
--     Logger.log_console (Logger.INFO, "Program started.")  -- writes log on info level to console
--     Logger.log_sd (Logger.INFO, gps_msg) -- writes GPS record to SD card
with SDLog;
with NVRAM;
with Buildinfo;
with HIL.Devices;
with HIL.UART;
with System;

--  @summary Simultaneously writes to UART, and SD card.
package body Logger with SPARK_Mode,
  Refined_State => (LogState => (queue_ulog, Logging_Task, logger_level, With_SDLog))
is

   --  the type for the queue buffer
   type Buffer_Ulog is array (Natural range <>) of ULog.Message;
   type bufpos is mod LOG_QUEUE_LENGTH;

   --  if GNATprove crashes with reference to that file,
   --  then you have run into bug KP-160-P601-005.
   --  workaround: move decl of protected type to package spec.

   --  protected type to implement the ULog queue
   protected type Ulog_Queue_T is
      procedure New_Msg (msg : in ULog.Message);
      --  enqueue new message. this is not blocking, except to ensure mutex.
      --  it is fast (only memcpy), but it can silently fail if buffer is full.
      --  FIXME: how can we specify a precondition on the private variable?
      --  for now we put an assertion in the body

      entry Get_Msg (msg : out ULog.Message);
      --  try to get new message from buffer. if empty, this is blocking
      --  until buffer has data, and then returns it.
      --  FIXME: how can we specify a precondition on the private variable?
      --  for now we put an assertion in the body

      function Get_Num_Overflows return Natural;
      --  query how often the buffer overflowed. If this happens, either increase
      --  the buffer QUEUE_LENGTH, or increase priority of the logger task.

      function Get_Length return Natural;
      --  query number of messages waiting in the logging queue.
   private
      Buffer : Buffer_Ulog (0 .. LOG_QUEUE_LENGTH - 1);
      --  cannot use a discriminant for this (would violate No_Implicit_Heap_Allocations)

      Num_Queued    : Natural := 0;
      Not_Empty     : Boolean := False; -- simple barrier (Ravenscar)
      Pos_Read      : bufpos := 0;
      Pos_Write     : bufpos := 0;
      Num_Overflows : Natural := 0;
      --  cannot use a dynamic predicate to etablish relationship, because this requires
      --  a record. But we cannot have a record, since this would make Not_Empty a
      --  non-simple barrier (=> Ravenscar violation).
   end Ulog_Queue_T;

   --  sporadic logging task waking up when message is enqueued
   task Logging_Task is
      pragma Priority (System.Priority'First); -- lowest prio for logging
   end Logging_Task;

   ----------------------------
   --  PROTOTYPES
   ----------------------------

   function Image (level : Log_Level) return String;

   ----------------------------
   --  INTERNAL STATES
   ----------------------------

   queue_ulog   : Ulog_Queue_T;
   logger_level : Log_Level := DEBUG;
   With_SDLog   : Boolean := False;

   --  the task which logs to SD card in the background
   task body Logging_Task is
      msg : ULog.Message;
      BUFLEN : constant := 1024;
      bytes : HIL.Byte_Array (1 .. BUFLEN);
      len : Natural;
   begin
      loop
         queue_ulog.Get_Msg (msg); -- under mutex
         ULog.Serialize_Ulog (msg, len, bytes); -- this can be slow again
         --  TODO: translate into FileBytes with length=len
         --  SDLog.Write_Log (Data => bytes);
         --  TODO: occasionally log queue state (overflows, num_queued).
      end loop;
   end Logging_Task;

   --  implementation of the message queue
   protected body Ulog_Queue_T is
      procedure New_Msg (msg : in ULog.Message) is
      begin
         Buffer (Integer (Pos_Write)) := msg;
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
         pragma Assert ((Not_Empty and (Num_Queued > 0)) or ((not Not_Empty) and (Num_Queued = 0)));
      end New_Msg;

      entry Get_Msg (msg : out ULog.Message) when Not_Empty is
      begin
         pragma Assume (Num_Queued > 0); -- via barrier and assert in New_Msg

         msg := Buffer (Integer (Pos_Read));
         Pos_Read := Pos_Read + 1;
         Num_Queued := Num_Queued - 1;

         Not_Empty := Num_Queued > 0;
         pragma Assert ((Not_Empty and (Num_Queued > 0)) or ((not Not_Empty) and (Num_Queued = 0)));
      end Get_Msg;

      function Get_Num_Overflows return Natural is (Num_Overflows);
      function Get_Length return Natural is (Num_Queued);
   end Ulog_Queue_T;

   ----------------------------
   --  Instantiation / Body   --
   ----------------------------

   --  HAL, only change Adapter to port Code
   package body Adapter is
      procedure init (status : out Init_Error_Code) is
      begin
         --  HIL.UART.configure; already done in CPU.initialize
         status := SUCCESS;
      end init;

      procedure write (message : Message_Type) is
         CR : constant Character := Character'Val (13); -- ASCII
         --  LF : constant Character := Character'Val (10);
      begin
         HIL.UART.write(HIL.Devices.Console, HIL.UART.toData_Type ( message & CR ) );
      end write;	
   end Adapter;

   procedure init (status : out Init_Error_Code) is
   begin
      SDLog.Init;
      Adapter.init (status);
   end init;

   function Image (level : Log_Level) return String is
   begin
      return (case level is
                 when SENSOR => "S: ",
                 when ERROR => "E: ",
                 when WARN  => "W: ",
                 when INFO  => "I: ",
                 when DEBUG => "D: ",
                 when TRACE => "T: "
             );
   end Image;

   procedure log_console (msg_level : Log_Level; message : Message_Type) is
   begin
      if Log_Level'Pos (msg_level) <= Log_Level'Pos (logger_level) then
         Adapter.write (Image (msg_level) & message);
      end if;
   end log_console;

   procedure log_sd (level : Log_Level; message : ULog.Message) is
   begin
      if Log_Level'Pos (level) <= Log_Level'Pos (logger_level) then
         queue_ulog.New_Msg (message);
      end if;
   end log_sd;

   procedure set_Log_Level (level : Log_Level) is
   begin
      logger_level := level;
   end set_Log_Level;

   procedure Start_SDLog is
      num_boots : HIL.Byte;
   begin
      NVRAM.Load (variable => NVRAM.VAR_BOOTCOUNTER, data => num_boots);
      declare
         buildstring : constant String := Buildinfo.Short_Datetime;
         fname       : constant String := num_boots'Img & ".log";
         BUFLEN      : constant := 1024;
         bytes       : HIL.Byte_Array (1 .. BUFLEN);
         len         : Natural;
         valid       : Boolean := True;
      begin
         With_SDLog := False;
         if not SDLog.Start_Logfile (dirname => buildstring, filename => fname)
         then
            log_console (Logger.ERROR, "Cannot create logfile: " & buildstring & "/" & fname);
         else
            log_console (Logger.INFO, "Log name: " & buildstring & "/" & fname);
            With_SDLog := True;
         end if;

         --  write file header (ULog message definitions)
         ULog.Init;
         Get_Ulog_Defs_Loop :
         loop
            ULog.Get_Header_Ulog (bytes, len, valid);
            exit Get_Ulog_Defs_Loop when not valid;
            --  TODO: convert to FileData and write to SD card
            --  SDLog.Write_Log (Data => bytes);
            null;
         end loop Get_Ulog_Defs_Loop;
      end;
   end Start_SDLog;

end Logger;
