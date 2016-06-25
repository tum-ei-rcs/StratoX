-- Institution: Technische Universitaet Muenchen
-- Department:  Real-Time Computer Systems (RCS)
-- Project:     StratoX

with HIL.SPI; use HIL.SPI;

package body FM25v02.Driver with
   Refined_State => (State => Is_Init)
is

   DEVICE : constant HIL.SPI.Device_ID_Type := HIL.SPI.FRAM;
   procedure FRAM_Write (data : HIL.SPI.Data_Type) is
   begin
      -- device is so fast that it can write at bus speed
      -- thus, no ready poll required.
      HIL.SPI.write (Device => DEVICE, data => data);
   end FRAM_Write;

   procedure FRAM_Read (data : out HIL.SPI.Data_Type) is
   begin
      HIL.SPI.read (Device => DEVICE, data => data);
   end FRAM_Read;

   procedure Init
   is
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

   procedure Self_Check (Status : out Boolean) is
   begin
      Status := False;
      -- TODO: read device ID or something
   end Self_Check;

   procedure Read_Byte (addr : Address; byte : out HIL.Byte) is
      spidata : HIL.SPI.Data_Type := (0,0); -- FIXME
   begin
      FRAM_Write (spidata); -- TODO: query data@address
      FRAM_Read (spidata); -- TODO: poll response
   end Read_Byte;

   procedure Write_Byte (addr : Address; byte : HIL.Byte) is
      spidata : HIL.SPI.Data_Type := (0,0); -- TODO
   begin
      FRAM_Write (spidata);
   end Write_Byte;
end FM25v02.Driver;
