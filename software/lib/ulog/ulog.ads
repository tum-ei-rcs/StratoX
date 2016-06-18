-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Author: Martin Becker (becker@rcs.ei.tum.de)
with Interfaces;
with HIL;

-- @summary
-- Implements a serialization of log objects (records,
-- string messages, etc.) according to the self-describing
-- ULOG file format used in PX4.
-- The serialized byte array is returned.
package ULog with SPARK_Mode is

   -- root type/base class for polymorphism. all visible to clients.
   type Message is abstract tagged record
      Timestamp : Interfaces.Unsigned_64 := 0;
      Length    : Interfaces.Unsigned_16 := 0;
   end record;

   function Size (msg : in Message) return Interfaces.Unsigned_16 is abstract;
   --  return length of serialized object in bytes

   procedure Serialize (msg : in Message'Class; bytes : out HIL.Byte_Array);
   --  turn object into ULOG byte array
   --  indefinite argument (class-wide type)

   procedure Get_Header (bytes : out HIL.Byte_Array);
   --  every ULOG file starts with a header, which is generated here

private
   procedure Flatten (msg : in Message; bytes : out HIL.Byte_Array);
   --  the actual serialization

end ULog;
