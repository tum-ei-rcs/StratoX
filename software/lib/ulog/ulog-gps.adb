--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with Ada.Text_IO; -- TODO: remove

--  @summary
--  implements ULOG GPS message
package body ULog.GPS with SPARK_Mode is

   overriding
   procedure Get_Serialization (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array) is
   begin
      --  TODO: serialize the extensions in GPS message
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
      return 10; -- TODO
   end Get_Size;

   overriding
   function Self (msg : in Message) return ULog.Message'Class is
   begin
      Ada.Text_IO.Put_Line ("Self of ulog.gps");
      return Message'(msg);
   end Self;

end ULog.GPS;
