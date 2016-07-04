--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with Ada.Tags;
with Ada.Text_IO; -- TODO: remove
with ULog.Identifiers;

--  @summary
--  Implements a serialization of log objects (records,
--  string messages, etc.) according to the self-describing
--  ULOG file format used in PX4.
--  The serialized byte array is returned.
--  this package tries to dispatch to the specific decendants,
--  e.g., ULog.GPS.
package body ULog with SPARK_Mode => Off is

   procedure Get_Serialization (msg : in Message; bytes : out HIL.Byte_Array) is
   begin
      --  TODO: serialize things from root type
      null;
   end Get_Serialization;

   procedure Serialize (msg : in Message'Class; bytes : out HIL.Byte_Array) is
      thistag : constant Ada.Tags.Tag := msg'Tag; -- private type -> 'Tag not permitted in SPARK
      --  this_ID : constant ULog.Identifiers.ID := ULog.Identifiers.Make_ID (thistag);
   begin
      --  TODO: serialize common fields
      --  TODO: then serialize the message ID (use 'this_ID' as ID)
      --  finally, dispatch to serialize the specific message body
      Get_Serialization (msg, bytes); -- dispatch to msg's specific type
   end Serialize;

   procedure Format (msg : in Message'Class; bytes : out HIL.Byte_Array) is
   begin
      Get_Format (msg => msg, bytes => bytes); -- dispatch
   end Format;

   procedure Get_Format
     (msg : in Message; bytes : out HIL.Byte_Array) is
   begin
      null;
      --  TODO
   end Get_Format;

   function Get_Size (msg : in Message) return Interfaces.Unsigned_16 is (0);

   function Self (msg : in Message) return ULog.Message'Class is begin
      Ada.Text_IO.Put_Line ("Self of ulog");
      return Message'(msg);
   end Self;

   function Size (msg : in Message'Class) return Interfaces.Unsigned_16 is
      --  descendant : Message'Class := Self;
      descendant : Message'Class := Self (msg); -- factory function
   begin
      --Ada.Text_IO.Put_Line ("Size() called for type=" & Describe_Func (descendant));
      return Get_Size (descendant); -- dispatch

   end Size;

   procedure Get_Header (bytes : out HIL.Byte_Array) is
   begin
      --  TODO: iterate (if possible) over all types in Message'Class and
      --  dump their format in the bytes array
      null;
   end Get_Header;

   function Describe_Func (msg : in Message'Class) return String is
   begin
      return Ada.Tags.Expanded_Name (msg'Tag);
   end Describe_Func;

   procedure Describe (msg : in Message'Class; namestring : out String) is
   begin
      namestring := Ada.Tags.Expanded_Name (msg'Tag);
   end Describe;

end ULog;
