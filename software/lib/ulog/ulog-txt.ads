--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with ULog;
with Interfaces;

--  @summary
--  implements ULOG Text message
package ULog.Txt with SPARK_Mode is

   --  extends base record, specific for GPS. Implicitely tagged (RM 3.9-2).
   type Message is new ULog.Message with record
      text      : String (1 .. 128);
      text_last : Integer := 0;
   end record;

   procedure Set_Text (msg : in out Message; text : String);

private
   overriding
   function Self (msg : in Message) return ULog.Message'Class;

   overriding
   procedure Get_Serialization (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array);

   overriding
   function Get_Size (msg : in Message) return Interfaces.Unsigned_16;

   overriding
   procedure Get_Format (msg : in Message; bytes : out HIL.Byte_Array);

end ULog.Txt;
