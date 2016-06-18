-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Author: Martin Becker (becker@rcs.ei.tum.de)
with ULog;
with Interfaces;

-- @summary
-- implements ULOG GPS message
package ULog.GPS with SPARK_Mode is

   type fixtype is (NOFIX, DEADR, FIX2D, FIX3D, FIX3DDEADR, FIXTIME);

   --  extends base record specific for GPS
   type Message_GPS is new Message with record
      gps_week : Interfaces.Integer_16    := 0;
      gps_msec : Interfaces.Unsigned_64   := 0;
      fix      : fixtype                  := NOFIX;
      nsat     : Interfaces.Unsigned_8    := 0;
      lat      : Interfaces.IEEE_Float_32 := 0.0;
      lon      : Interfaces.IEEE_Float_32 := 0.0;
      alt      : Interfaces.IEEE_Float_32 := 0.0;
   end record;

   overriding function Size (msg : in Message_GPS) return Interfaces.Unsigned_16;

private
   overriding procedure Flatten (msg : in Message_GPS; bytes : out HIL.Byte_Array);

end ULog.GPS;
