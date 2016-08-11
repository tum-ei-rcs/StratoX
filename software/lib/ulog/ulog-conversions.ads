--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with Interfaces; use Interfaces;
with HIL; use HIL;

--  @summary convert various types to bytearrays
private package ULog.Conversions with SPARK_Mode is

   type Conversion_Tag is private;

   procedure New_Conversion (t : out Conversion_Tag);
   procedure Set_Name (t : in out Conversion_Tag; s : String)
     with Pre => s'Length > 0;
   function Get_Size (t : in Conversion_Tag) return Natural;
   function Get_Format (t : in Conversion_Tag) return ULog_Format;
   function Get_Name (t : in Conversion_Tag) return ULog_Name;
   function Get_Labels (t : in Conversion_Tag) return ULog_Label;
   procedure Append_Unlabeled_Bytes (t : in out Conversion_Tag;
                                     buf : in out HIL.Byte_Array; tail : HIL.Byte_Array);

   --  only these should be used by the serialization routines:

   procedure Append_Float (t : in out Conversion_Tag; label : String;
                           buf : in out HIL.Byte_Array; tail : Float)
     with Pre => label'Length > 0;

   procedure Append_Uint8 (t : in out Conversion_Tag; label : String;
                           buf : in out HIL.Byte_Array; tail : Unsigned_8)
     with Pre => label'Length > 0;
   procedure Append_Uint16 (t : in out Conversion_Tag; label : String;
                            buf : in out HIL.Byte_Array; tail : Unsigned_16)
     with Pre => label'Length > 0;
   procedure Append_Uint32 (t : in out Conversion_Tag; label : String;
                            buf : in out HIL.Byte_Array; tail : Unsigned_32)
     with Pre => label'Length > 0;
   procedure Append_Uint64 (t : in out Conversion_Tag; label : String;
                            buf : in out HIL.Byte_Array; tail : Unsigned_64)
     with Pre => label'Length > 0;
   procedure Append_Int8 (t : in out Conversion_Tag; label : String;
                          buf : in out HIL.Byte_Array; tail : Integer_8)
     with Pre => label'Length > 0;
   procedure Append_Int16 (t : in out Conversion_Tag; label : String;
                           buf : in out HIL.Byte_Array; tail : Integer_16)
     with Pre => label'Length > 0;
   procedure Append_Int32 (t : in out Conversion_Tag; label : String;
                           buf : in out HIL.Byte_Array; tail : Integer_32)
     with Pre => label'Length > 0;
   procedure Append_Int64 (t : in out Conversion_Tag; label : String;
                           buf : in out HIL.Byte_Array; tail : Integer_64)
     with Pre => label'Length > 0;
   procedure Append_String64 (t : in out Conversion_Tag;
                              label : String;
                              buf  : in out HIL.Byte_Array;
                              tail : String;
                              slen : Natural)
     with Pre => label'Length > 0 and then slen <= tail'Length;
   --  append the part tail'First ... tail'First + slen to buf
   --  takes only the first 64 bytes. If longer, then spit before call.

private

   type Label_Collect_Type is record
      Labels : ULog_Label := (others => HIL.Byte (0));
      Length : Natural := 0;
   end record;

   type Format_Collect_Type is record
      Format : ULog_Format := (others => HIL.Byte (0));
      Length : Natural := 0;
   end record;

   type Conversion_Tag is record
      Total_Size     : Natural := 0;
      Label_Collect  : Label_Collect_Type;
      Format_Collect : Format_Collect_Type;
      Name           : ULog_Name := (others => HIL.Byte (0));
   end record;

end ULog.Conversions;
