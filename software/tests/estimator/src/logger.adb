package body logger with Refined_State => (LogState => null)
is
   procedure init(status : out Init_Error_Code) is null;

   procedure log(level : Log_Level; message : Message_Type) is null;
   procedure log_ulog(level : Log_Level; msg : ULog.Message'Class) is null;

   procedure set_Log_Level(level : Log_Level) is null;

   package body Adapter is
      procedure init(status : out Init_Error_Code) is null;
      procedure write(message : Message_Type) is null;
   end Adapter;
end logger;
