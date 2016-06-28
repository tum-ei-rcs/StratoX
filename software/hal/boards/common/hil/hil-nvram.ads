--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with HIL.Devices.NVRAM;

--  @summary
--  Target-independent specification for HIL of NVRAM
package HIL.NVRAM with
     Spark_Mode => On
is

   subtype Address is HIL.Devices.NVRAM.NVRAM_Address; -- expose type
   -- the target-specific packages must specify the address type

   procedure Init;
   -- initialize the communication to the FRAM

   procedure Self_Check (Status : out Boolean);
   -- run a self-check.
   -- @return true on success

   procedure Read_Byte (addr : Address; byte : out HIL.Byte);
   -- read a single byte

   procedure Write_Byte (addr : Address; byte : HIL.Byte);
--     with Pre => Is_Init;
   -- write a single byte

end HIL.NVRAM;
