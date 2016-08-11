--  Institution: Technische Universitaet Muenchen
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--  Authors:     Martin Becker (becker@rcs.ei.tum.de)
with Interfaces; use Interfaces;
with HIL.NVRAM;  use HIL.NVRAM;
with HIL;        use HIL;
with Buildinfo;  use Buildinfo;
with Fletcher16;

package body NVRAM with SPARK_Mode => On,   -- Somehow this package includes interrupts, which are accesses
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
          ck_a : HIL.Byte := 0;
          ck_b : HIL.Byte := 0;
       end record;
   HDR_OFF_CK_A : constant HIL.NVRAM.Address := 0; -- GNATprove cannot handle this yet: framhdr.ck_a'Position;
   HDR_OFF_CK_B : constant HIL.NVRAM.Address := 1;
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
      build_date : constant String := Compilation_ISO_Date & Compilation_Time;
      crc        : constant Fletcher16_String.Checksum_Type :=
        Fletcher16_String.Checksum (build_date);
   begin
      newhdr := (ck_a => crc.ck_a, ck_b => crc.ck_b);
   end Make_Header;

   procedure Write_Header (hdr : in NVRAM_Header) is
   begin
      HIL.NVRAM.Write_Byte (addr => Hdr_To_Address + HDR_OFF_CK_A, byte => hdr.ck_a);
      HIL.NVRAM.Write_Byte (addr => Hdr_To_Address + HDR_OFF_CK_B, byte => hdr.ck_b);
   end Write_Header;

   procedure Read_Header (framhdr : out NVRAM_Header) is
   begin
      HIL.NVRAM.Read_Byte (addr => Hdr_To_Address + HDR_OFF_CK_A, byte => framhdr.ck_a);
      HIL.NVRAM.Read_Byte (addr => Hdr_To_Address + HDR_OFF_CK_B, byte => framhdr.ck_b);
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
      num_boots : HIL.Byte;
   begin
      HIL.NVRAM.Init;
      Validate_Contents;

      --  maintain boot counter
      Load (VAR_BOOTCOUNTER, num_boots);
      if num_boots < HIL.Byte'Last then
         num_boots := num_boots + 1;
         Store (VAR_BOOTCOUNTER, num_boots);
      end if;
   end Init;

   procedure Self_Check (Status : out Boolean) is
   begin
      HIL.NVRAM.Self_Check (Status);
   end Self_Check;

   procedure Load (variable : Variable_Name; data : out HIL.Byte) is
   begin
      HIL.NVRAM.Read_Byte (addr => Var_To_Address (variable), byte => data);
   end Load;

   procedure Load (variable : in Variable_Name; data : out Float) is
      bytes : Byte_Array_4 := (others => 0); -- needs init, because SPARK cannot prove via call
   begin
      for index in Natural range 0 .. 3 loop
         HIL.NVRAM.Read_Byte (addr => Var_To_Address (
                              Variable_Name'Val (Variable_Name'Pos( variable ) + index )),
                              byte => bytes(bytes'First + index));
      end loop;
      data := HIL.toFloat (bytes);
   end Load;

   procedure Store (variable : Variable_Name; data : in HIL.Byte) is
   begin
      HIL.NVRAM.Write_Byte (addr => Var_To_Address (variable), byte => data);
   end Store;

   procedure Store (variable : in Variable_Name; data : in Float) is
      bytes : constant Byte_Array_4 := HIL.toBytes (data );
   begin
      for index in Natural range 0 .. 3 loop
         HIL.NVRAM.Write_Byte (addr => Var_To_Address (
                               Variable_Name'Val (Variable_Name'Pos( variable ) + index )),
                               byte => bytes(bytes'First + index));
      end loop;
   end Store;

   procedure Reset is
      hdr_this : NVRAM_Header;
   begin
      Make_Header (hdr_this);
      Clear_Contents;
      Write_Header (hdr_this);
   end Reset;

end NVRAM;
