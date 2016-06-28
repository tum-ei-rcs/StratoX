-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Software Configuration
--
-- Authors: Martin Becker (becker@rcs.ei.tum.de)
with FM25v0x;

--  @summary
--  Target-specific types for the NVRAM in Pixracer V1.
package HIL.Devices.NVRAM with SPARK_Mode is

   --  Pixracer has 256kbit FRAM
   package FM25v02 is new FM25v0x (2**15);
   subtype NVRAM_Address is FM25v02.Address;
end HIL.Devices.NVRAM;
