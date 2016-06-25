--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with FM25V01.Driver; -- FIXME: make generic

--  @summary
--  Target-specific mapping for HIL of NVRAM
package body HIL.NVRAM with
     Spark_Mode => On
is

   procedure Init renames FM25V01.Driver.Init;

   procedure Self_Check (Status : out Boolean) renames FM25V01.Driver.Self_Check;

   procedure Read_Byte (addr : Address; byte : out HIL.Byte) renames FM25V01.Driver.Read_Byte;

   procedure Write_Byte (addr : Address; byte : HIL.Byte) renames FM25V01.Driver.Write_Byte;

end HIL.NVRAM;
