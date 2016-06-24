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

with HIL.UART;

package body Logger with SPARK_Mode
is

   logger_level : Log_Level := DEBUG;

   ----------------------------
   --  Instatiation / Body   --
   ----------------------------

   --  HAL, only change Adapter to port Code
   package body Adapter is
      procedure init (status : out Init_Error_Code) is
      begin
         HIL.UART.configure;
         status := SUCCESS;
      end init;

      procedure write (message : Message_Type) is
         --  LF : Character := Character'Val(10);
         CR : constant Character := Character'Val (13);  -- ASCII
      begin
         HIL.UART.write (HIL.UART.Console, HIL.UART.toData_Type (message & CR ) );
      end write;        
   end Adapter;

   procedure init (status : out Init_Error_Code) is
   begin
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
                 when TRACE => "  > "
             );
   end Image;
   pragma Unreferenced (Image);

   procedure log (level : Log_Level; message : Message_Type)
   is
   begin
      if Log_Level'Pos (level) <= Log_Level'Pos (logger_level) then
         Adapter.write (Log_Level'Image (level) & message);
      end if;
   end log;

   procedure set_Log_Level (level : Log_Level) is
   begin
      logger_level := level;
   end set_Log_Level;
   pragma Unreferenced (set_Log_Level);

end Logger;
