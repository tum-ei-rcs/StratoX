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

   MANUFACTURER : constant HAL.Byte_Array (1 .. 7) := (7 => 16#C2#, others => 16#7F#);
   FAMILY       : constant HAL.UInt3 := 1;
   DENSITY      : constant HAL.UInt5 := 2;

   DEVICE : constant HIL.SPI.Device_ID_Type := HIL.SPI.FRAM;
   procedure Device_Send (data : HIL.SPI.Data_Type) is
   begin
      -- device is so fast that it can write at bus speed
      -- thus, no ready poll required.
      HIL.SPI.write (Device => DEVICE, data => data);
   end Device_Send;

   procedure Device_Receive (data : out HIL.SPI.Data_Type) is
   begin
      HIL.SPI.read (Device => DEVICE, data => data);
   end Device_Receive;

   procedure Init is
   begin
      if Is_Init then
         return;
      end if;

      while Clock < FM25v02_STARTUP_TIME_MS loop
         null;
      end loop;

      -- TODO: set write-enable (WREN)

      Is_Init := True;
   end Init;

   procedure Read_Status_Register (Status : out FM25v02.Protocol.Status_Register) is
      cmd      : constant HIL.SPI.Data_Type (1 .. 1) := (1 => Interfaces.Unsigned_8 (FM25v02.Protocol.OP_RDSR));
      response : HIL.SPI.Data_Type ( 1 .. FM25v02.Protocol.Status_Register'Size );
   begin
      Device_Send (cmd);

      -- FIXME: this is ugly ... there is a type mismatch (HAL.Byte vs HIL.Byte)
      Device_Receive (response);
      for k in response'Range loop
         Status.Data_Array (k) := response (k);
      end loop;
   end Read_Status_Register;

   procedure Read_Device_ID (Dev_ID : out FM25v02.Protocol.Msg_Device_ID) is
      cmd      : constant HIL.SPI.Data_Type (1 .. 1) := (1 => Interfaces.Unsigned_8 (FM25v02.Protocol.OP_RDID));
      response : HIL.SPI.Data_Type ( 1 .. FM25v02.Protocol.Msg_Device_ID'Size );
   begin
      Device_Send (cmd);
      Device_Receive (response);
      for k in response'Range loop
         Dev_ID.Data_Array (k) := response (k);
      end loop;
   end Read_Device_ID;

   procedure Self_Check (Status : out Boolean) is
      deviceid   : FM25v02.Protocol.Msg_Device_ID;
      use type Interfaces.Unsigned_8;
   begin
      Read_Device_ID (deviceid);
      Status := True;
      --  check expected identifiers
      Status := Status and (MANUFACTURER = deviceid.Manufacturer_ID);
      Status := Status and (FAMILY = deviceid.Family);
      Status := Status and (DENSITY = deviceid.Density);
   end Self_Check;

   procedure Read_Byte (addr : Address; byte : out HIL.Byte) is
      cmd : HIL.SPI.Data_Type (1 .. 3);
      rsp : HIL.SPI.Data_Type (1 .. 1);
   begin
      cmd (1) := Interfaces.Unsigned_8 (FM25v02.Protocol.OP_RDSR);
      cmd (2) := 0; -- addr1
      cmd (3) := 0; -- addr2
      Device_Send (cmd);
      Device_Receive (rsp);
      byte := rsp (1);
   end Read_Byte;

   procedure Write_Byte (addr : Address; byte : HIL.Byte) is
      spidata : HIL.SPI.Data_Type := (0,0); -- TODO
   begin
      Device_Send (spidata);
   end Write_Byte;
end FM25v02.Driver;
