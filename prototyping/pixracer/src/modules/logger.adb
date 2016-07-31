--  Project: MART - Modular Airborne Real-Time Testbed
--  System:  Emergency Recovery System
--  Author: Emanuel Regnath (emanuel.regnath@tum.de)
--
--  Description:
--     allows logging of structured messages at several logging levels.
--     Simultaneously writes to UART, to SD card and to data link (TODO).
--
--  Usage:
--     Logger.init  -- initializes the Logger
--     Logger.log(Logger.INFO, "Program started.")  -- writes log on info level

with SDLog;
with NVRAM;
with Buildinfo;
with HIL.Devices;
with HIL.UART;

package body Logger with SPARK_Mode is

   ----------------------------
   --  PROTOTYPES
   ----------------------------

   function Image (level : Log_Level) return String;

   logger_level : Log_Level := DEBUG;
   With_SDLog : Boolean := False;

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
         LF : constant Character := Character'Val (10);
      begin
         HIL.UART.write (HIL.Devices.TELE2,
                            HIL.UART.toData_Type (message & CR & LF));
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

   procedure log (msg_level : Log_Level; message : Message_Type) is
   begin
      if Log_Level'Pos (msg_level) <= Log_Level'Pos (logger_level) then
         Adapter.write (Image (msg_level) & message);
      end if;
   end log;

   procedure set_Log_Level (level : Log_Level) is
   begin
      logger_level := level;
   end set_Log_Level;
   pragma Unreferenced (set_Log_Level);

   procedure Start_SDLog is
      num_boots : HIL.Byte;
   begin
      NVRAM.Load (variable => NVRAM.VAR_BOOTCOUNTER, data => num_boots);
      declare
         buildstring : constant String := Buildinfo.Short_Datetime;
         fname       : constant String := num_boots'Img & ".log";
         BUFLEN      : constant := 1024;
         bytes       : HIL.Byte_Array (1 .. BUFLEN);
      begin
         With_SDLog := False;
         if not SDLog.Start_Logfile (dirname => buildstring, filename => fname)
         then
            log (Logger.ERROR, "Cannot create logfile: " & buildstring & "/" & fname);
         else
            log (Logger.INFO, "Log name: " & buildstring & "/" & fname);
            With_SDLog := True;
         end if;

         --  write file header (ULog message definitions)
         --  TODO: in chunks, because it's describing all messages
         --  ULog.Get_Header (bytes);

         --  TODO: convert to FileData and write to SD card
         --  SDLog.Write_Log (Data => bytes);
      end;
   end Start_SDLog;

end Logger;
