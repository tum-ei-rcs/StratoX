--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with HIL; use HIL;
with Ada.Unchecked_Conversion;

--  @summary convert various types to bytearrays
package body ULog.Conversions with SPARK_Mode is

   type Label_Collect_Type is record
      Labels : ULog_Label := (others => HIL.Byte (0));
      Length : Natural := 0;
   end record;

   type Format_Collect_Type is record
      Format : ULog_Format := (others => HIL.Byte (0));
      Length : Natural := 0;
   end record;

   ----------------------
   --  Internal States
   ----------------------

   Total_Size     : Natural := 0;
   Label_Collect  : Label_Collect_Type;
   Format_Collect : Format_Collect_Type;
   Name           : ULog_Name := (others => HIL.Byte (0));


   --  Format characters in the format string for binary log messages
   --  DONE:
   --    f   : float
   --    Z   : char[64]
   --    B   : uint8_t
   --  TODO:
   --    b   : int8_t
   --    h   : int16_t
   --    H   : uint16_t
   --    i   : int32_t
   --    I   : uint32_t
   --    n   : char[4]
   --    N   : char[16]
   --    c   : int16_t * 100
   --    C   : uint16_t * 100
   --    e   : int32_t * 100
   --    E   : uint32_t * 100
   --    L   : int32_t latitude/longitude
   --    M   : uint8_t flight mode
   --    q   : int64_t
   --    Q   : uint64_t

   ----------------
   --  PROTOTYPES
   ----------------

   procedure Add_Labeled (label  : String;
                          format : Character;
                          buf    : in out HIL.Byte_Array;
                          tail   : HIL.Byte_Array);

   procedure Copy_To_Buffer (buf : in out HIL.Byte_Array;
                             tail : HIL.Byte_Array);

   -----------
   --  Reset
   -----------

   procedure New_Conversion is begin
      Total_Size := 0;
      Name   := (others => HIL.Byte (0));
      Label_Collect  := (Labels => (others => HIL.Byte (0)), Length => 0);
      Format_Collect := (Format => (others => HIL.Byte (0)), Length => 0);
   end New_Conversion;

   --------------
   --  Get_Size
   --------------

   function Get_Size return Natural is (Total_Size);

   ---------------
   --  Get_Format
   ---------------

   function Get_Format return ULog_Format is (Format_Collect.Format);

   ---------------
   --  Get_Labels
   ---------------

   function Get_Labels return ULog_Label is (Label_Collect.Labels);

   ---------------
   --  Get_Name
   ---------------

   function Get_Name return ULog_Name is (Name);

   ---------------
   --  Set_Name
   ---------------

   procedure Set_Name (s : String) is
      subtype shortname is String (1 .. ULog_Name'Length);
      function To_Name is new Ada.Unchecked_Conversion (shortname, ULog_Name);
      tmp : shortname := (others => Character'Val (0));
      slen : constant Integer := (if s'Length > tmp'Length then tmp'Length else s'Length);
   begin
      if slen > 0 then
         tmp (tmp'First .. tmp'First + slen - 1) := s (s'First .. s'First + slen - 1);
      end if;
      Name := To_Name (tmp);
   end Set_Name;

   ---------------------
   --  BUffer_Capacity
   ---------------------

   function Buffer_Capacity (buf : HIL.Byte_Array) return Integer is (buf'Length - Total_Size);

   -------------------
   --  Add_To_Buffer
   -------------------

   --  add as much as we can to the buffer, without overflowing
   procedure Copy_To_Buffer (buf : in out HIL.Byte_Array; tail : HIL.Byte_Array) is
   begin
      if tail'Length <= Buffer_Capacity (buf) then
         buf (buf'First + Total_Size .. buf'First + Total_Size + tail'Length) := tail;
      end if;
      --  keep counting, so caller can see potential overflow
      Total_Size := Total_Size + tail'Length;
   end Copy_To_Buffer;

   ------------------------
   --  Append_Labeled
   ------------------------

   procedure Add_Labeled (label  : String;
                             format : Character;
                             buf    : in out HIL.Byte_Array;
                             tail   : HIL.Byte_Array)
   is
      lbl_cap : constant Integer := Label_Collect.Labels'Length - Label_Collect.Length;
      fmt_cap : constant Integer := Format_Collect.Format'Length - Format_Collect.Length;
   begin
      if Buffer_Capacity (buf) >= tail'Length and
      then lbl_cap > label'Length and  -- not >=, because of ','
      then fmt_cap > 0
      then
         Copy_To_Buffer (buf => buf, tail => tail);
         declare
            idx_lbl_lo : constant Integer := Label_Collect.Labels'First + Label_Collect.Length;
            idx_lbl_hi : constant Integer := idx_lbl_lo + label'Length; -- not '-1', because of ','
            idx_fmt    : constant Integer := Format_Collect.Format'First + Format_Collect.Length;
            subtype VarString is String (1 .. label'Length);
            subtype VarBytes is HIL.Byte_Array (1 .. VarString'Length);
            function To_Bytes is new Ada.Unchecked_Conversion (VarString, VarBytes);
         begin
            Label_Collect.Labels (idx_lbl_lo .. idx_lbl_hi) := HIL.Byte (Character'Pos (','))
              & To_Bytes (label);
            Format_Collect.Format (idx_fmt) := HIL.Byte (Character'Pos (format));
         end;
      end if;
      --  keep counting, so caller can see potential overflow
      Label_Collect.Length := Label_Collect.Length + label'Length + 1;
      Format_Collect.Length := Format_Collect.Length + 1;
   end Add_Labeled;

   ----------------------------
   --  Append_Unlabeled_Bytes
   ----------------------------

   procedure Append_Unlabeled_Bytes (buf : in out HIL.Byte_Array;
                                     tail : HIL.Byte_Array) is
   begin
      Copy_To_Buffer (buf => buf, tail => tail);
   end Append_Unlabeled_Bytes;


   ------------------
   --  Append_Float
   ------------------

   procedure Append_Float (label : String; buf : in out HIL.Byte_Array; tail : Float) is
      subtype Byte4 is Byte_Array (1 .. 4);
      function To_Bytes is new Ada.Unchecked_Conversion (Float, Byte4);
   begin
      Add_Labeled (label, 'f', buf, To_Bytes (tail));
   end Append_Float;

   ------------------
   --  Append_Uint8
   ------------------

   procedure Append_Uint8 (label : String; buf : in out HIL.Byte_Array; tail : Unsigned_8) is
      barr : constant Byte_Array := (1 => HIL.Byte (tail));
   begin
      Add_Labeled (label, 'B', buf, barr);
   end Append_Uint8;

   -------------------
   --  Append_String
   -------------------

   procedure Append_String (label : String; buf : in out HIL.Byte_Array;
                            tail : String; slen : Natural)
   is
      subtype String64 is String (1 .. 64);
      subtype Byte64 is Byte_Array (1 .. String64'Length);
      function To_Byte64 is new Ada.Unchecked_Conversion (String64, Byte64);

      tmp : String64 := (others => Character'Val (0));
      len : constant Integer := (if slen > tmp'Length then tmp'Length else slen);
   begin
      if len > 0 then
         tmp (tmp'First .. tmp'First + len - 1) := tail (tail'First .. tail'First + len - 1);
      end if;
      Add_Labeled (label, 'Z', buf, To_Byte64 (tmp));
   end Append_String;

end ULog.Conversions;
