-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Author: Martin Becker (becker@rcs.ei.tum.de)

-- @summary
-- Implements a serialization of log objects (records,
-- string messages, etc.) according to the self-describing
-- ULOG file format used in PX4.
-- The serialized byte array is returned.
package body ULog is

   procedure Flatten (msg : in Message; bytes : out HIL.Byte_Array) is
   begin
      -- TODO: serialize things from root type
      null;
   end Flatten;

   procedure Serialize (msg : in Message'Class; bytes : out HIL.Byte_Array) is
   begin
      Flatten (msg, bytes); -- dynamic dispatching depending on actual type of class-wide argument
   end Serialize;

   procedure Get_Header (bytes : out HIL.Byte_Array) is
   begin
      -- TODO: iterate (if possible) over all types in Message'Class and
      -- dump their format in the bytes array
      null;
   end Get_Header;
end ULog;
