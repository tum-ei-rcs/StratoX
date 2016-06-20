-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Author: Martin Becker (becker@rcs.ei.tum.de)
--
-- @summary
-- implements ULOG GPS message
package body ULog.GPS is

   overriding
   procedure Flatten (msg : in Message_GPS; bytes : out HIL.Byte_Array) is
   begin
      Flatten (Message (msg), bytes); -- call root
      -- TODO: serialize the extensions in GPS message
      null;
   end Flatten;

   overriding
   function Size ( msg : in Message_GPS ) return Interfaces.Unsigned_16 is (0); -- TODO

   overriding
   procedure Get_Format (msg : in Message_GPS; bytes : out HIL.Byte_Array) is
   begin
      null;
   end Get_Format;
end ULog.GPS;