-- Institution: Technische Universitaet Muenchen
-- Department:  Real-Time Computer Systems (RCS)
-- Project:     StratoX
-- Authors:     Martin Becker (becker@rcs.ei.tum.de)

with Interfaces;
with HAL; use HAL;
with HIL.SPI; use HIL.SPI;
with FM25v02.Protocol;

package body FM25v02.Driver with
   Refined_State => (State => Is_Init)
is

   DEVICE       : constant HIL.SPI.Device_ID_Type := HIL.SPI.FRAM;
   MANUFACTURER : constant HAL.Byte_Array (1 .. 7) := (7 => 16#C2#, others => 16#7F#);
   FAMILY       : constant HAL.UInt3 := 1;
   DENSITY      : constant HAL.UInt5 := 2;

   procedure Read_Status_Register (Status : out FM25v02.Protocol.Status_Register) is
      cmd      : constant HIL.SPI.Data_Type (1 .. 1) := (1 => Interfaces.Unsigned_8 (FM25v02.Protocol.OP_RDSR));
      response : HIL.SPI.Data_Type (1 .. Status.Data_Array'Length);
   begin
      HIL.SPI.transfer (Device => DEVICE, Data_TX => cmd, Data_RX => response);
      for k in response'Range loop
         Status.Data_Array (k) := response (k);
      end loop;
   end Read_Status_Register;

   procedure Write_Enable is
      cmd  : constant HIL.SPI.Data_Type (1 .. 1) := (1 => Interfaces.Unsigned_8 (FM25v02.Protocol.OP_WREN));
   begin
      HIL.SPI.write (Device => DEVICE, data => cmd);
   end Write_Enable;

   procedure Init is
   begin
      if not Is_Init then
         while Clock < FM25v02_STARTUP_TIME_MS loop
            null;
         end loop;
         Is_Init := True;
         --  nothing to do here
      end if;
   end Init;

   procedure Read_Device_ID (Dev_ID : out FM25v02.Protocol.Msg_Device_ID) is
      cmd      : constant HIL.SPI.Data_Type (1 .. 1) := (1 => Interfaces.Unsigned_8 (FM25v02.Protocol.OP_RDID));
      response : HIL.SPI.Data_Type ( 1 .. Dev_ID.Data_Array'Length  );
   begin
      HIL.SPI.transfer (Device => DEVICE, Data_TX => cmd, Data_RX => response);
      for k in response'Range loop
         Dev_ID.Data_Array (k) := response (k);
      end loop;
   end Read_Device_ID;

   procedure Self_Check (Status : out Boolean) is
      deviceid   : FM25v02.Protocol.Msg_Device_ID;
      use type Interfaces.Unsigned_8;
      -- sreg : FM25v02.Protocol.Status_Register;
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
      cmd (1) := Interfaces.Unsigned_8 (FM25v02.Protocol.OP_READ);
      cmd (2) := HIL.Byte (addr / 2**8);   -- high
      cmd (3) := HIL.Byte (addr mod 2**8); -- low
      HIL.SPI.transfer (Device => DEVICE, Data_TX => cmd, Data_RX => rsp);
      byte := rsp (1);
   end Read_Byte;

   procedure Write_Byte (addr : Address; byte : HIL.Byte) is
      cmd : HIL.SPI.Data_Type (1 .. 4);
   begin
      Write_Enable; -- this *really* is required every time.
                    -- the write_enable is cleared after each
                    -- transaction
      cmd (1) := Interfaces.Unsigned_8 (FM25v02.Protocol.OP_WRITE);
      cmd (2) := HIL.Byte (addr / 2**8);   -- high
      cmd (3) := HIL.Byte (addr mod 2**8); -- low
      cmd (4) := byte;
      HIL.SPI.write (Device => DEVICE, Data => cmd);
   end Write_Byte;
end FM25v02.Driver;
