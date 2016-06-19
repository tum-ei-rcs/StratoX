-- Institution: Technische Universitaet Muenchen
-- Department:  Real-Time Computer Systems (RCS)
-- Project:     StratoX

with HIL.SPI; use HIL.SPI;

package body FM25v01.Driver with
   Refined_State => (State => Is_Init)
is

   procedure Init
   is
   begin
      if Is_Init then
         return;
      end if;

      while Clock < FM25v01_STARTUP_TIME_MS loop
         null;
      end loop;

      Is_Init := True;
   end Init;

   procedure Self_Check (Status : out Boolean) is
   begin
      Status := False;

      -- TODO: read device ID or something
   end Self_Check;

   procedure Read_Byte (addr : Address; byte : out HIL.Byte) is
   begin
      null;
   end Read_Byte;

   procedure Write_Byte (addr : Address; byte : HIL.Byte) is
   begin
      null;
   end Write_Byte;
end FM25v01.Driver;
