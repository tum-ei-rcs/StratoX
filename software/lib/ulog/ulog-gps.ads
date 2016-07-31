--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with ULog;
with Interfaces;

--  @summary
--  implements ULOG GPS message
package ULog.GPS with SPARK_Mode is

   type fixtype is (NOFIX, DEADR, FIX2D, FIX3D, FIX3DDEADR, FIXTIME);

   --  extends base record, specific for GPS. Implicitely tagged (RM 3.9-2).
   type Message is new ULog.Message with record
      gps_week : Interfaces.Integer_16    := 0;
      gps_msec : Interfaces.Unsigned_64   := 0;
      fix      : fixtype                  := NOFIX;
      nsat     : Interfaces.Unsigned_8    := 0;
      lat      : Interfaces.IEEE_Float_32 := 0.0;
      lon      : Interfaces.IEEE_Float_32 := 0.0;
      alt      : Interfaces.IEEE_Float_32 := 0.0;
   end record;

private
   overriding
   function Self (msg : in Message) return ULog.Message'Class;

   overriding
   procedure Get_Serialization (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array);

   overriding
   function Get_Size (msg : in Message) return Interfaces.Unsigned_16;

   overriding
   procedure Get_Format (msg : in Message; bytes : out HIL.Byte_Array);

end ULog.GPS;
