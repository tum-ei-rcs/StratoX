-- Institution: Technische Universitaet Muenchen
-- Department:  Real-Time Computer Systems (RCS)
-- Project:     StratoX
-- Authors:     Martin Becker (becker@rcs.ei.tum.de)
with HAL;
with System;

--  @summary
--  The SPI protocol for the FRAM chip.
private package FM25v02.Protocol is

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
            Reserved_1_1   : HAL.Bit;
            Write_Enabled  : Boolean := False; -- write enable <=> soft lock disable
            Soft_Lock      : Soft_Lock_Field := BP_LOCK_NONE;
            Reserved_4_6   : HAL.UInt3;
            Enable_HW_Lock : Boolean := True; -- by default, activate hardware write protect pin
         when True =>
            Data_Array     : HAL.Byte_Array (1 .. 1);
      end case;
   end record
     with Unchecked_Union, Size => 8,
     Bit_Order => System.Low_Order_First; -- TODO: check
   for Status_Register use record
      Reserved_1_1   at 0 range 0 .. 0;
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
   for Msg_Device_ID use record
      Reserved_0_2    at 0 range 0 .. 2;
      Rev             at 0 range 3 .. 5;
      Sub             at 0 range 6 .. 7;
      Density         at 0 range 8 .. 12;
      Family          at 0 range 13 .. 15;
      Manufacturer_ID at 0 range 16 .. 71;
      Data_Array      at 0 range 0 .. 71;
   end record;

end FM25V02.Protocol;
