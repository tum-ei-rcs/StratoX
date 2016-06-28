--  Institution: Technische Universität München
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--  Authors:     Martin Becker (becker@rcs.ei.tum.de)
with Interfaces; use Interfaces;
with HIL.NVRAM;  use HIL.NVRAM;
with Fletcher16;

package body NVRAM with SPARK_Mode,
   Refined_State => (Memory_State => null)
is

   use type HIL.NVRAM.Address;

   ----------------------------------
   --  instantiate generic Fletcher16
   ----------------------------------

   function "+" (Left : HIL.Byte; Right : Character) return HIL.Byte;
      --  provide add function for checksumming characters

   function "+" (Left : HIL.Byte; Right : Character) return HIL.Byte is
      val : constant Integer := Character'Pos (Right);
      rbyte : constant HIL.Byte := HIL.Byte (val);
   begin
      return Left + rbyte;
   end "+";

   --  instantiation of checksum
   package Fletcher16_String is new Fletcher16 (Index_Type => Positive,
                                                Element_Type => Character,
                                                Array_Type => String);

   ----------------------------------
   --  Types
   ----------------------------------

   --  the header in NVRAM is a checksum, which
   --  depends on build date/time
   type NVRAM_Header is
       record
          ck_a : HIL.Byte;
          ck_b : HIL.Byte;
       end record;
   for NVRAM_Header'Size use 16;

   ----------------------------------
   --  body specs
   ----------------------------------

   function Var_To_Address (var : in Variable_Name) return HIL.NVRAM.Address;
   --  get address of variable in RAM
   --  no need for postcondition.

   function Hdr_To_Address return HIL.NVRAM.Address;
   --  get address of header in RAM
   --  no need for postcondition.

   function Get_Default (var : in Variable_Name) return HIL.Byte;
   --  read default value of variable

   procedure Make_Header (newhdr : out NVRAM_Header);
   --  generate a new header for this build

   procedure Write_Header (hdr : in NVRAM_Header);
   --  write a header to RAM

   procedure Read_Header (framhdr : out NVRAM_Header);
   --  read header from RAM.

   procedure Clear_Contents;
   --  set all variables in NVRAM to their default

   procedure Validate_Contents;
   --  check whether the entries in NVRAM are valid for the current
   --  compilation version of this program. if not, set all of them
   --  to their defaults (we cannot defer this, since the program could
   --  reset at any point in time).

   ----------------------------------
   --  Bodies
   ----------------------------------

   function Hdr_To_Address return HIL.NVRAM.Address is (0);
   --  header's address is fixed at beginning of NVRAM

   procedure Make_Header (newhdr : out NVRAM_Header) is
      function Compilation_Date return String -- implementation-defined (GNAT)
        with Import, Convention => Intrinsic;
      function Compilation_Time return String -- implementation-defined (GNAT)
        with Import, Convention => Intrinsic;

      build_date : constant String := Compilation_Date & Compilation_Time;
      crc        : constant Fletcher16_String.Checksum_Type :=
        Fletcher16_String.Checksum (build_date);
   begin
      newhdr := (ck_a => crc.ck_a, ck_b => crc.ck_b);
   end Make_Header;

   procedure Write_Header (hdr : in NVRAM_Header) is
   begin
      --  FIXME: can this be done safer. Maybe with aggregates?
      HIL.NVRAM.Write_Byte (addr => Hdr_To_Address +
                         hdr.ck_a'Position, byte => hdr.ck_a);
      HIL.NVRAM.Write_Byte (addr => Hdr_To_Address +
                         hdr.ck_b'Position, byte => hdr.ck_b);
   end Write_Header;

   procedure Read_Header (framhdr : out NVRAM_Header) is
   begin
      --  FIXME: can this be done safer. Maybe with aggregates?
      HIL.NVRAM.Read_Byte (addr => Hdr_To_Address +
                        framhdr.ck_a'Position, byte => framhdr.ck_a);
      HIL.NVRAM.Read_Byte (addr => Hdr_To_Address +
                        framhdr.ck_b'Position, byte => framhdr.ck_b);
   end Read_Header;

   function Get_Default (var : in Variable_Name) return HIL.Byte
   is (Variable_Defaults (var));

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

   function Var_To_Address (var : in Variable_Name) return HIL.NVRAM.Address
   is (HIL.NVRAM.Address ((NVRAM_Header'Size + 7) / 8) -- ceiling bit -> bytes
       + Variable_Name'Pos (var));

   procedure Init is
   begin
      HIL.NVRAM.Init;
      Validate_Contents;
   end Init;

   procedure Self_Check (Status : out Boolean) is
   begin
      HIL.NVRAM.Self_Check (Status);
   end Self_Check;

   procedure Load (variable : Variable_Name; data : out HIL.Byte) is
   begin
      HIL.NVRAM.Read_Byte (addr => Var_To_Address (variable), byte => data);
   end Load;

   procedure Store (variable : Variable_Name; data : in HIL.Byte) is
   begin
      HIL.NVRAM.Write_Byte (addr => Var_To_Address (variable), byte => data);
   end Store;

   procedure Reset is
      hdr_this : NVRAM_Header;
   begin
      Make_Header (hdr_this);
      Clear_Contents;
      Write_Header (hdr_this);
   end Reset;

end NVRAM;
