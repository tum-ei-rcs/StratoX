package body ulog is
   procedure Serialize (msg : in Message'Class; bytes : out HIL.Byte_Array) is null;
   procedure Format (msg : in Message'Class; bytes : out HIL.Byte_Array) is null;
   procedure Get_Header (bytes : out HIL.Byte_Array) is null;
   procedure Describe (msg : in Message'Class; namestring : out String) is null;
   function Describe_Func (msg : in Message'Class) return String is ("hallo");
   function Size (msg : in Message'Class)
                  return Interfaces.Unsigned_16 is (0);
   function Self (msg : in Message) return ULog.Message'Class is (msg);
   procedure Get_Serialization (msg : in Message; bytes : out HIL.Byte_Array) is null;
   function Get_Size (msg : in Message) return Interfaces.Unsigned_16 is (0);
   procedure Get_Format
     (msg   : in  Message;
      bytes : out HIL.Byte_Array) is null;
end ulog;
