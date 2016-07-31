--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with Ada.Text_IO; -- TODO: remove

--  @summary
--  implements ULOG Text message
package body ULog.Txt with SPARK_Mode is

   procedure Set_Text (msg : in out Message; text : String) is
      len    : constant Integer := text'Length;
      minlen : constant Integer := (if len > msg.text'Length then msg.text'Length else len);
   begin
      msg.text := text;
      msg.text_last := msg.text'First + minlen - 1;
   end Set_Text;

   overriding
   procedure Get_Serialization (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array) is
   begin
      --  TODO: serialize the extensions in text message
      null;
   end Get_Serialization;

   overriding
   procedure Get_Format (msg : in Message; bytes : out HIL.Byte_Array) is
   begin
      null;
   end Get_Format;

   overriding
   function Get_Size (msg : in Message) return Interfaces.Unsigned_16 is
   begin
      return msg.text'Length;
   end Get_Size;

   overriding
   function Self (msg : in Message) return ULog.Message'Class is
   begin
      Ada.Text_IO.Put_Line ("Self of ulog.text");
      return Message'(msg);
   end Self;

end ULog.Txt;
