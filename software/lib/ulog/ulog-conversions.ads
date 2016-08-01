--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with Interfaces; use Interfaces;

--  @summary convert various types to bytearrays
private package ULog.Conversions with SPARK_Mode is

   procedure New_Conversion;

   procedure Set_Name (s : String);

   function Get_Size return Natural;
   function Get_Format return ULog_Format;
   function Get_Name return ULog_Name;
   function Get_Labels return ULog_Label;

   procedure Append_Unlabeled_Bytes (buf : in out HIL.Byte_Array; tail : HIL.Byte_Array);

   procedure Append_Float (label : String; buf : in out HIL.Byte_Array; tail : Float);

   procedure Append_Uint8 (label : String; buf : in out HIL.Byte_Array; tail : Unsigned_8);

   procedure Append_String (label : String;
                            buf  : in out HIL.Byte_Array;
                            tail : String;
                            slen : Natural);
   --  append the part tail'First ... tail'First + slen to buf
end ULog.Conversions;
