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
   --    b   : int8_t
   --    H   : uint16_t
   --    h   : int16_t
   --    i   : int32_t
   --    I   : uint32_t
   --    q   : int64_t
   --    Q   : uint64_t
   --  TODO:
   --    n   : char[4]
   --    N   : char[16]
   --    c   : int16_t * 100
   --    C   : uint16_t * 100
   --    e   : int32_t * 100
   --    E   : uint32_t * 100
   --    L   : int32_t latitude/longitude
   --    M   : uint8_t flight mode

   ----------------
   --  PROTOTYPES
   ----------------

   procedure Add_Labeled (label  : String;
                          format : Character;
                          buf    : in out HIL.Byte_Array;
                          tail   : HIL.Byte_Array)
     with Pre => label'Length > 0 and then label'First <= label'Last;

   procedure Copy_To_Buffer (buf : in out HIL.Byte_Array;
                             tail : HIL.Byte_Array);

   -----------
   --  Reset
   -----------

   procedure New_Conversion is
   begin
      Total_Size     := 0;
      Name           := (others => HIL.Byte (0));
      Label_Collect  := (Labels => (others => HIL.Byte (0)), Length => 0);
      Format_Collect := (Format => (others => HIL.Byte (0)), Length => 0);
   end New_Conversion;

   -----------
   --  Init
   -----------

   procedure Init is
   begin
      New_Conversion;
   end Init;

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
         tmp (tmp'First .. tmp'First - 1 + slen) := s (s'First .. s'First - 1 + slen);
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
      if tail'Length > 0 then
         if tail'Length <= Buffer_Capacity (buf) then
            pragma Assert (Buffer_Capacity (buf) > 0);
            buf (buf'First + Total_Size .. buf'First + Total_Size - 1 + tail'Length) := tail;
         end if;
         --  keep counting, so caller can see potential overflow
         if Natural'Last - Total_Size >= tail'Length then
            Total_Size := Total_Size + tail'Length;
         else
            Total_Size := Natural'Last;
         end if;
      end if;
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
      then lbl_cap > label'Length  -- not >=, because of ','
      and then fmt_cap > 0
      then
         Copy_To_Buffer (buf => buf, tail => tail);
         if Label_Collect.Length > 0 then
            Label_Collect.Length := Label_Collect.Length + 1;
            Label_Collect.Labels (Label_Collect.Length) := HIL.Byte (Character'Pos (','));
         end if;
         declare
            idx_lbl_lo : constant Integer := Label_Collect.Labels'First + Label_Collect.Length;
            idx_lbl_hi : constant Integer := idx_lbl_lo + label'Length - 1;
            idx_fmt    : constant Integer := Format_Collect.Format'First + Format_Collect.Length;
            subtype VarString is String (1 .. label'Length);
            subtype VarBytes is HIL.Byte_Array (1 .. label'Length);
            function To_Bytes is new Ada.Unchecked_Conversion (VarString, VarBytes);
            d : constant VarBytes := To_Bytes (label);
         begin
            Label_Collect.Labels (idx_lbl_lo .. idx_lbl_hi) := d;
            Format_Collect.Format (idx_fmt) := HIL.Byte (Character'Pos (format));
         end;
      end if;
      --  keep counting, so caller can see potential overflow
      if Natural'Last - Label_Collect.Length > label'Length then
         Label_Collect.Length := Label_Collect.Length + label'Length - 1;
      else
         Label_Collect.Length := Natural'Last;
      end if;
      if Natural'Last - Format_Collect.Length > 0 then
         Format_Collect.Length := Format_Collect.Length + 1;
      else
         Format_Collect.Length := Natural'Last;
      end if;
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


   ------------------
   --  Append_Int8
   ------------------

   procedure Append_Int8 (label : String; buf : in out HIL.Byte_Array; tail : Integer_8) is
      subtype Byte1 is Byte_Array (1 .. 1);
      function To_Bytes is new Ada.Unchecked_Conversion (Integer_8, Byte1);
   begin
      Add_Labeled (label, 'b', buf, To_Bytes (tail));
   end Append_Int8;

   ------------------
   --  Append_Uint16
   ------------------

   procedure Append_Uint16 (label : String; buf : in out HIL.Byte_Array; tail : Unsigned_16) is
      subtype Byte2 is Byte_Array (1 .. 2);
      function To_Bytes is new Ada.Unchecked_Conversion (Unsigned_16, Byte2);
   begin
      Add_Labeled (label, 'H', buf, To_Bytes (tail));
   end Append_Uint16;

   ------------------
   --  Append_Int16
   ------------------

   procedure Append_Int16 (label : String; buf : in out HIL.Byte_Array; tail : Integer_16) is
      subtype Byte2 is Byte_Array (1 .. 2);
      function To_Bytes is new Ada.Unchecked_Conversion (Integer_16, Byte2);
   begin
      Add_Labeled (label, 'h', buf, To_Bytes (tail));
   end Append_Int16;


   ------------------
   --  Append_UInt32
   ------------------

   procedure Append_Uint32 (label : String; buf : in out HIL.Byte_Array; tail : Unsigned_32) is
      subtype Byte4 is Byte_Array (1 .. 4);
      function To_Bytes is new Ada.Unchecked_Conversion (Unsigned_32, Byte4);
   begin
      Add_Labeled (label, 'I', buf, To_Bytes (tail));
   end Append_Uint32;

   ------------------
   --  Append_Int32
   ------------------

   procedure Append_Int32 (label : String; buf : in out HIL.Byte_Array; tail : Integer_32) is
      subtype Byte4 is Byte_Array (1 .. 4);
      function To_Bytes is new Ada.Unchecked_Conversion (Integer_32, Byte4);
   begin
      Add_Labeled (label, 'i', buf, To_Bytes (tail));
   end Append_Int32;

   ------------------
   --  Append_UInt64
   ------------------

   procedure Append_Uint64 (label : String; buf : in out HIL.Byte_Array; tail : Unsigned_64) is
      subtype Byte8 is Byte_Array (1 .. 8);
      function To_Bytes is new Ada.Unchecked_Conversion (Unsigned_64, Byte8);
   begin
      Add_Labeled (label, 'Q', buf, To_Bytes (tail));
   end Append_Uint64;

   ------------------
   --  Append_Int64
   ------------------

   procedure Append_Int64 (label : String; buf : in out HIL.Byte_Array; tail : Integer_64) is
      subtype Byte8 is Byte_Array (1 .. 8);
      function To_Bytes is new Ada.Unchecked_Conversion (Integer_64, Byte8);
   begin
      Add_Labeled (label, 'q', buf, To_Bytes (tail));
   end Append_Int64;

   -------------------
   --  Append_String
   -------------------

   procedure Append_String64 (label : String; buf : in out HIL.Byte_Array;
                            tail : String; slen : Natural)
   is
      subtype String64 is String (1 .. 64);
      subtype Byte64 is Byte_Array (1 .. String64'Length);
      function To_Byte64 is new Ada.Unchecked_Conversion (String64, Byte64);

      tmp : String64 := (others => Character'Val (0));
      len : constant Integer := (if slen > tmp'Length then tmp'Length else slen);
   begin
      if len > 0 then
         tmp (tmp'First .. tmp'First - 1 + len) := tail (tail'First .. tail'First - 1 + len);
      end if;
      Add_Labeled (label, 'Z', buf, To_Byte64 (tmp));
   end Append_String64;

end ULog.Conversions;
