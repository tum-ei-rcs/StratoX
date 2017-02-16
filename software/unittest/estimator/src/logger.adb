with Ada.Text_IO;

package body logger with Refined_State => (LogState => null)
is
   procedure init(status : out Init_Error_Code) is null;

   procedure Start_SDLog is null;


   function Image (level : Log_Level) return String is
   begin
      case level is
         when SENSOR => return "S: ";
         when ERROR => return "E: ";
         when WARN => return "W: ";
         when INFO => return "I: ";
         when DEBUG => return "D: ";
         when TRACE => return "T: ";
      end case;
   end Image;

   procedure log(msg_level : Log_Level; message : Message_Type) is
   begin
      if msg_level = WARN or msg_level = INFO or msg_level = DEBUG then
         Ada.Text_IO.Put_Line (Image (msg_level) & message);
      end if;
   end log;

   procedure log_console (msg_level : Log_Level; message : Message_Type) is
   begin
      log (msg_level, message);
   end log_console;

   procedure log_sd (msg_level : Log_Level; message : ULog.Message) is null;

   procedure log_ulog(level : Log_Level; msg : ULog.Message) is null;

   procedure set_Log_Level(level : Log_Level) is null;

   package body Adapter is
      procedure init_adapter(status : out Init_Error_Code) is null;
      procedure write(message : Message_Type) is null;
   end Adapter;
end logger;
