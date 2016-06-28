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

with HIL.Devices;
with HIL.UART;

package body Logger with SPARK_Mode is

   ----------------------------
   --  PROTOTYPES
   ----------------------------

   function Image (level : Log_Level) return String;

   logger_level : Log_Level := DEBUG;

   ----------------------------
   --  Instatiation / Body   --
   ----------------------------

   procedure init (status : out Init_Error_Code) is
   begin
      --  nothing to do
      null;
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

   procedure log (msg_level : Log_Level; message : Message_Type) is
      CR : constant Character := Character'Val (13);
      LF : constant Character := Character'Val (10);
   begin
      if Log_Level'Pos (msg_level) <= Log_Level'Pos (logger_level) then
            HIL.UART.write (HIL.Devices.TELE2,
                            HIL.UART.toData_Type (Image (msg_level) &
                                message & CR & LF));
      end if;
   end log;

   procedure set_Log_Level (level : Log_Level) is
   begin
      logger_level := level;
   end set_Log_Level;
   pragma Unreferenced (set_Log_Level);

end Logger;
