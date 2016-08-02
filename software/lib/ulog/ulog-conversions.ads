--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
--  XXX! FIXME not thread safe. only one user at a time.
with Interfaces; use Interfaces;

--  @summary convert various types to bytearrays
private package ULog.Conversions with SPARK_Mode is

   procedure Init_Conv;
   procedure New_Conversion;
   procedure Set_Name (s : String)
     with Pre => s'Length > 0 and then s'Length <= 4;
   function Get_Size return Natural;
   function Get_Format return ULog_Format;
   function Get_Name return ULog_Name;
   function Get_Labels return ULog_Label;
   procedure Append_Unlabeled_Bytes (buf : in out HIL.Byte_Array; tail : HIL.Byte_Array);

   --  only these should be used by the serialization routines:

   procedure Append_Float (label : String; buf : in out HIL.Byte_Array; tail : Float)
     with Pre => label'Length > 0;
   procedure Append_Uint8 (label : String; buf : in out HIL.Byte_Array; tail : Unsigned_8)
     with Pre => label'Length > 0;
   procedure Append_Uint16 (label : String; buf : in out HIL.Byte_Array; tail : Unsigned_16)
     with Pre => label'Length > 0;
   procedure Append_Uint32 (label : String; buf : in out HIL.Byte_Array; tail : Unsigned_32)
     with Pre => label'Length > 0;
   procedure Append_Uint64 (label : String; buf : in out HIL.Byte_Array; tail : Unsigned_64)
     with Pre => label'Length > 0;
   procedure Append_Int8 (label : String; buf : in out HIL.Byte_Array; tail : Integer_8)
     with Pre => label'Length > 0;
   procedure Append_Int16 (label : String; buf : in out HIL.Byte_Array; tail : Integer_16)
     with Pre => label'Length > 0;
   procedure Append_Int32 (label : String; buf : in out HIL.Byte_Array; tail : Integer_32)
     with Pre => label'Length > 0;
   procedure Append_Int64 (label : String; buf : in out HIL.Byte_Array; tail : Integer_64)
     with Pre => label'Length > 0;
   procedure Append_String64 (label : String;
                              buf  : in out HIL.Byte_Array;
                              tail : String;
                              slen : Natural)
     with Pre => label'Length > 0 and then slen <= tail'Length;
   --  append the part tail'First ... tail'First + slen to buf
   --  takes only the first 64 bytes. If longer, then spit before call.
end ULog.Conversions;
