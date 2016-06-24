--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author: Martin Becker (becker@rcs.ei.tum.de)
with Interfaces;
with HIL;

--  @summary
--  Implements a serialization of log objects (records,
--  string messages, etc.) according to the self-describing
--  ULOG file format used in PX4.
--  The serialized byte array is returned.
--
--  We cannot make this abstract, because it would require
--  access types to use polymorphism, and that's not SPARK.
package ULog with SPARK_Mode is

   --  root type/base class for polymorphism. all visible to clients.
   type Message is tagged record
      Timestamp : Interfaces.Unsigned_64 := 0;
      Length    : Interfaces.Unsigned_16 := 0;
   end record;

   ---------------------------------------------------------------------
   --                   Non-Primitive operations                      --
   --  (not inherited; available for all members of class-wide type)  --
   ---------------------------------------------------------------------

   procedure Serialize (msg : in Message'Class; bytes : out HIL.Byte_Array);
   --  turn object into ULOG byte array
   --  indefinite argument (class-wide type)
   --  FIXME: maybe overload attribute Output?

   procedure Format (msg : in Message'Class; bytes : out HIL.Byte_Array);
   --  turn object's format description into ULOG byte array

   procedure Get_Header (bytes : out HIL.Byte_Array);
   --  every ULOG file starts with a header, which is generated here
   --  for all known message types

   procedure Describe (msg : in Message'Class; namestring : out String); -- is abstract
   --  return a readable string identifying message type

   function Describe_Func (msg : in Message'Class) return String;
   --  same as above, but as function. REquired because of string.

   ------------------------------------
   --      Primitive operations      --
   --  (inherited in Message'Class)  --
   ------------------------------------
   -- those are NOT dispatched

   function Size (msg : in Message'Class) return Interfaces.Unsigned_16; -- is abstract;
   --  return length of serialized object in bytes
   --  Note that this has nothing to do with the size of the struct, since
   --  the representation in ULOG format may be different.

private

   ------------------------------------
   --      Primitive operations      --
   --  (inherited in Message'Class)  --
   ------------------------------------
   function Self (msg : in Message) return ULog.Message'Class;
   --  factory function to convert to specific child view

   procedure Get_Serialization (msg : in Message; bytes : out HIL.Byte_Array);
   --  the actual serialization

   function Get_Size (msg : in Message) return Interfaces.Unsigned_16;

   procedure Get_Format
     (msg   : in  Message;
      bytes : out HIL.Byte_Array); -- is abstract
   --  for a specific message type, generate the FMT header.
   --
   --  FIXME: we actually don't need an instance of the message. Actually we want
   --  the equivalent to a static member function in C++. Maybe a type attribute?
   --
   --  FIXME: we want it private, but abstract does not support this.

end ULog;
