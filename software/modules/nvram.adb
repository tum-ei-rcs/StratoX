-- Institution: Technische Universität München
-- Department:  Real-Time Computer Systems (RCS)
-- Project:     StratoX
-- Authors:     Martin Becker (becker@rcs.ei.tum.de)
-- FIXME: replace with HIL version
with FM25v01.Driver; use FM25v01.Driver;
with Interfaces; use Interfaces;
with Fletcher16;

package body NVRAM with SPARK_Mode,
   Refined_State => ( Memory_State => null )
is

   -- provide add function for checksumming characters
   function "+" (Left : HIL.Byte; Right : Character) return HIL.Byte is
      val : constant Integer := Character'Pos (Right);
      rbyte : constant HIL.Byte := HIL.Byte (val);
   begin
      return Left + rbyte;
   end "+";

   -- instantiation of checksum
   package Fletcher16_String is new Fletcher16 (Index_Type => Positive,
                                                Element_Type => Character,
                                                Array_Type => String);

   ----------------------------------
   --  body specs
   ----------------------------------

   function Var_To_Address (var : in Variable_Name) return NVRAM.Address
     with Post => Var_To_Address'Result <= FM25v01.Driver.Address'Last;
   function Hdr_To_Address return NVRAM.Address is (0)
   with Post => Hdr_To_Address'Result <= FM25v01.Driver.Address'Last;

   ----------------------------------
   --  Types
   ----------------------------------

   --  At the beginning of FRAM, we put a header.
   type NVRAM_Header is
       record
          ck_a : HIL.Byte;
          ck_b : HIL.Byte;
       end record;
   for NVRAM_Header'Size use 16;

   ----------------------------------
   --  Bodies
   ----------------------------------

   procedure Make_Header (newhdr : out NVRAM_Header) is
      function Compilation_Date return String -- implementation-defined (GNAT)
        with Import, Convention => Intrinsic;
      function Compilation_Time return String -- implementation-defined (GNAT)
        with Import, Convention => Intrinsic;

      build_date : constant String := Compilation_Date;
      build_time : constant String := Compilation_Time;
      crc_date : constant Fletcher16_String.Checksum_Type :=
        Fletcher16_String.Checksum (build_date);
      crc_time : constant Fletcher16_String.Checksum_Type :=
        Fletcher16_String.Checksum (build_time);
      crc_all  : constant Fletcher16_String.Checksum_Type :=
        (ck_a => crc_date.ck_a + crc_time.ck_a,
         ck_b => crc_date.ck_b + crc_time.ck_b);
   begin
      newhdr := (ck_a => crc_all.ck_a, ck_b => crc_all.ck_b);
   end Make_Header;

   procedure Write_Header (hdr : in NVRAM_Header) is
      package FRAM renames FM25v01.Driver;
   begin
      -- FIXME: can this be done safer. Maybe with aggregates?
      FRAM.Write_Byte (addr => Hdr_To_Address + hdr.ck_a'Position, byte => hdr.ck_a);
      FRAM.Write_Byte (addr => Hdr_To_Address + hdr.ck_b'Position, byte => hdr.ck_b);
   end Write_Header;

   procedure Read_Header (framhdr : out NVRAM_Header) is
      package FRAM renames FM25v01.Driver;
   begin
      -- FIXME: can this be done safer. Maybe with aggregates?
      FRAM.Read_Byte (addr => Hdr_To_Address + framhdr.ck_a'Position, byte => framhdr.ck_a);
      FRAM.Read_Byte (addr => Hdr_To_Address + framhdr.ck_b'Position, byte => framhdr.ck_b);
   end Read_Header;

   --  FIXME: provide a way to let user define default
   function Get_Default (var : in Variable_Name) return HIL.Byte is (0); -- TODO

   --  set all variables in NVRAM to their default
   procedure Clear_Contents is
   begin
      for V in Variable_Name'Range loop
         declare
            defaultval : constant HIL.Byte := Get_Default (V);
         begin
            Store (variable => V, data => defaultval);
         end;
      end loop;
   end Clear_Contents;

   --  check whether the entries in NVRAM are valid for the current
   --  compilation version of this program. if not, set all of them
   --  to their defaults (we cannot defer this, since the program could
   --  reset at any point in time).
   procedure Validate_Contents is
      hdr_fram : NVRAM_Header;
      hdr_this : NVRAM_Header;
      same_header : Boolean;
   begin
      Read_Header (hdr_fram);
      Make_Header (hdr_this);
      same_header := hdr_fram = hdr_this;
      if not same_header then
         Clear_Contents;
         Write_Header (hdr_this);
      end if;
   end Validate_Contents;

   ----------------------------------
   --  implementation
   ----------------------------------

   function Var_To_Address (var : in Variable_Name) return NVRAM.Address
   is (NVRAM_Header'Size + Variable_Name'Pos (var));

   procedure Init is
      package FRAM renames FM25v01.Driver;
   begin
      FRAM.Init;
      Validate_Contents;
   end Init;

   procedure Self_Check (Status : out Boolean) is
      package FRAM renames FM25v01.Driver;
   begin
      FRAM.Self_Check (Status);
   end Self_Check;

   procedure Load (variable : Variable_Name; data : out HIL.Byte) is
      package FRAM renames FM25v01.Driver;
   begin
      FRAM.Read_Byte (addr => Var_To_Address (variable), byte => data);
   end Load;

   procedure Store (variable : Variable_Name; data : in HIL.Byte) is
      package FRAM renames FM25v01.Driver;
   begin
      FRAM.Write_Byte (addr => Var_To_Address (variable), byte => data);
   end Store;

end NVRAM;
