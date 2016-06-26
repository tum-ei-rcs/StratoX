--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with HIL.Devices.NVRAM;

--  @summary
--  Target-specific mapping for HIL of NVRAM
package body HIL.NVRAM with
     Spark_Mode => On
is

   procedure Init renames HIL.Devices.NVRAM.FM25v01.Init;

   procedure Self_Check (Status : out Boolean) renames HIL.Devices.NVRAM.FM25v01.Self_Check;

   procedure Read_Byte (addr : Address; byte : out HIL.Byte) renames HIL.Devices.NVRAM.FM25v01.Read_Byte;

   procedure Write_Byte (addr : Address; byte : HIL.Byte) renames HIL.Devices.NVRAM.FM25v01.Write_Byte;

end HIL.NVRAM;
