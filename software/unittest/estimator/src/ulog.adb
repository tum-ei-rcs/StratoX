package body ulog is
   procedure Init is null;
   procedure Serialize_Ulog (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array) is null;
   procedure Format (msg : in Message; bytes : out HIL.Byte_Array) is null;
   procedure Get_Header_Ulog (bytes : in out HIL.Byte_Array;
                              len : out Natural; valid : out Boolean) is null;
   procedure Describe (msg : in Message; namestring : out String) is null;
   function Describe_Func (msg : in Message) return String is ("hallo");
   function Size (msg : in Message)
                  return Interfaces.Unsigned_16 is (0);
   function Self (msg : in Message) return ULog.Message is (msg);
   procedure Get_Serialization (msg : in Message; bytes : out HIL.Byte_Array) is null;
   function Get_Size (msg : in Message) return Interfaces.Unsigned_16 is (0);
   procedure Get_Format
     (msg   : in  Message;
      bytes : out HIL.Byte_Array) is null;
end ulog;
