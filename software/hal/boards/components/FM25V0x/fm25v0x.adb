-- Institution: Technische Universitaet Muenchen
-- Department:  Real-Time Computer Systems (RCS)
-- Project:     StratoX
-- Authors:     Martin Becker (becker@rcs.ei.tum.de)

with System;
with Interfaces;
with HAL; use HAL;
with HIL.SPI; use HIL.SPI;

package body FM25v0x
   --with Refined_State => (State => Is_Init)
is

   ----------------------------------------
   --  DEVICE IDENTIFIER
   ----------------------------------------

   HIL_DEVICE   : constant HIL.SPI.Device_ID_Type := HIL.SPI.FRAM;
   MANUFACTURER : constant HAL.Byte_Array (1 .. 7) := (7 => 16#C2#, others => 16#7F#);
   FAMILY       : constant HAL.UInt3 := 1;
   DENSITY      : constant HAL.UInt5 := 2; -- TODO: must be function of MEMSIZE_BYTES

   ----------------------------------------
   --  PROTOCOL (FIXME: move to separate package, but cannot make child because of genericity.
   ----------------------------------------

   type Opcode_Type is mod 2**8;

   --  Opcodes
   OP_WREN  : constant Opcode_Type := 2#0000_0110#; -- write enable
   OP_WRDI  : constant Opcode_Type := 2#0000_0100#; -- write disable
   OP_RDSR  : constant Opcode_Type := 2#0000_0101#; -- read status reg
   OP_WRSR  : constant Opcode_Type := 2#0000_0001#; -- write status reg
   OP_READ  : constant Opcode_Type := 2#0000_0011#; -- read mem
   OP_FSTRD : constant Opcode_Type := 2#0000_1011#; -- fast read mem
   OP_WRITE : constant Opcode_Type := 2#0000_0010#; -- write mem
   OP_SLEEP : constant Opcode_Type := 2#1011_1001#; -- enter sleep
   OP_RDID  : constant Opcode_Type := 2#1001_1111#; -- read dev id

   type Soft_Lock_Field is
     (
      BP_LOCK_NONE,
      BP_LOCK_UPPER_FOURTH, -- protects 6000h to 7FFF
      BP_LOCK_UPPER_HALF,
      BP_LOCK_ALL)
     with Size => 2;
   for Soft_Lock_Field use
     (BP_LOCK_NONE => 0,
      BP_LOCK_UPPER_FOURTH => 1,
      BP_LOCK_UPPER_HALF => 2,
      BP_LOCK_ALL => 3);

   --  status register (record with union)
   type Status_Register
     (As_Bytearray : Boolean := False)
   is record
      case As_Bytearray is
         when False =>
            Reserved_0_0   : HAL.Bit;
            Write_Enabled  : Boolean := False; -- write enable <=> soft lock disable
            Soft_Lock      : Soft_Lock_Field := BP_LOCK_NONE;
            Reserved_4_6   : HAL.UInt3;
            Enable_HW_Lock : Boolean := True; -- by default, activate hardware write protect pin
         when True =>
            Data_Array     : HAL.Byte_Array (1 .. 1);
      end case;
   end record
     with Unchecked_Union, Size => 8,
     Bit_Order => System.Low_Order_First;
   for Status_Register use record
      Reserved_0_0   at 0 range 0 .. 0;
      Write_Enabled  at 0 range 1 .. 1;
      Soft_Lock      at 0 range 2 .. 3;
      Reserved_4_6   at 0 range 4 .. 6;
      Enable_HW_Lock at 0 range 7 .. 7;
      Data_Array     at 0 range 0 .. 7;
   end record;

   --  message with device information
   type Msg_Device_ID
     (As_Bytearray : Boolean := False)
   is record
      case As_Bytearray is
         when False =>
            Manufacturer_ID : HAL.Byte_Array (1 .. 7);
            Family          : HAL.UInt3;
            Density         : HAL.UInt5;
            Sub             : HAL.UInt2;
            Rev             : HAL.UInt3;
            Reserved_0_2    : HAL.UInt3;
         when True =>
            Data_Array : HAL.Byte_Array (1 .. 9);
      end case;
   end record
     with Unchecked_Union, Size => 72,
     Bit_Order => System.Low_Order_First;
   --  we get correct endianness, but bytes are switched
   --  (bytes are big endian, bits little)
   for Msg_Device_ID use record
      Reserved_0_2    at 8 range 0 .. 2; -- LSB
      Rev             at 8 range 3 .. 5;
      Sub             at 8 range 6 .. 7;
      Density         at 7 range 0 .. 4;
      Family          at 7 range 5 .. 7;
      Manufacturer_ID at 0 range 0 .. 55;
      Data_Array      at 0 range 0 .. 71;
   end record;

   ----------------------------------------
   --  IMPLEMENTATION
   ----------------------------------------

   procedure Read_Status_Register (Status : out Status_Register) is
      cmd      : constant HIL.SPI.Data_Type (1 .. 1) := (1 => Interfaces.Unsigned_8 (OP_RDSR));
      response : HIL.SPI.Data_Type (1 .. Status.Data_Array'Length);
   begin
      HIL.SPI.transfer (Device => HIL_DEVICE, Data_TX => cmd, Data_RX => response);
      for k in response'Range loop
         Status.Data_Array (k) := response (k);
      end loop;
   end Read_Status_Register;

   procedure Write_Enable is
      cmd  : constant HIL.SPI.Data_Type (1 .. 1) := (1 => Interfaces.Unsigned_8 (OP_WREN));
   begin
      HIL.SPI.write (Device => HIL_DEVICE, data => cmd);
   end Write_Enable;

   procedure Init is
   begin
      if not Is_Init then
         while Clock < FM25v0x_STARTUP_TIME_MS loop
            null;
         end loop;
         Is_Init := True;
         --  nothing to do here
      end if;
   end Init;

   procedure Read_Device_ID (Dev_ID : out Msg_Device_ID) is
      cmd      : constant HIL.SPI.Data_Type (1 .. 1) := (1 => Interfaces.Unsigned_8 (OP_RDID));
      response : HIL.SPI.Data_Type ( 1 .. Dev_ID.Data_Array'Length  );
   begin
      HIL.SPI.transfer (Device => HIL_DEVICE, Data_TX => cmd, Data_RX => response);
      for k in response'Range loop
         Dev_ID.Data_Array (k) := response (k);
      end loop;
   end Read_Device_ID;

   procedure Self_Check (Status : out Boolean) is
      deviceid   : Msg_Device_ID;
      use type Interfaces.Unsigned_8;
      -- sreg : Status_Register;
   begin
      Read_Device_ID (deviceid);
      Status := True;
      --  check expected identifiers
      Status := Status and (MANUFACTURER = deviceid.Manufacturer_ID);
      Status := Status and (FAMILY = deviceid.Family);
      Status := Status and (DENSITY = deviceid.Density);
      --  after boot the decice is supposed to be locked
      --  Read_Status_Register (Status => sreg);
      --  Status := Status and not sreg.Write_Enabled;
   end Self_Check;

   procedure Read_Byte (addr : Address; byte : out HIL.Byte) is
      cmd : HIL.SPI.Data_Type (1 .. 3);
      rsp : HIL.SPI.Data_Type (1 .. 1);
   begin
      cmd (1) := Interfaces.Unsigned_8 (OP_READ);
      cmd (2) := HIL.Byte (addr / 2**8);   -- high
      cmd (3) := HIL.Byte (addr mod 2**8); -- low
      HIL.SPI.transfer (Device => HIL_DEVICE, Data_TX => cmd, Data_RX => rsp);
      byte := rsp (1);
   end Read_Byte;

   procedure Write_Byte (addr : Address; byte : HIL.Byte) is
      cmd : HIL.SPI.Data_Type (1 .. 4);
   begin
      Write_Enable; -- this *really* is required every time.
                    -- the write_enable is cleared after each
                    -- transaction
      cmd (1) := Interfaces.Unsigned_8 (OP_WRITE);
      cmd (2) := HIL.Byte (addr / 2**8);   -- high
      cmd (3) := HIL.Byte (addr mod 2**8); -- low
      cmd (4) := byte;
      HIL.SPI.write (Device => HIL_DEVICE, Data => cmd);
   end Write_Byte;
end FM25v0x;
