-- Institution: Technische Universität München
-- Department:  Real-Time Computer Systems (RCS)
-- Project:     StratoX
-- Authors:     Martin Becker (becker@rcs.ei.tum.de)

package body NVRAM is
   procedure Init is
      package FRAM renames FM25v01.Driver;
   begin
      FRAM.Init;
   end Init;

   procedure Self_Check (Status : out Boolean) is
      package FRAM renames FM25v01.Driver;
   begin
      FRAM.Self_Check (Status);
   end Self_Check;

   procedure Load (variable : Address; data : out HIL.Byte) is
      package FRAM renames FM25v01.Driver;
   begin
      FRAM.Read_Byte (addr => FRAM.Address (variable), byte => data);
   end Load;

   procedure Store (variable : Address; data : in HIL.Byte) is
      package FRAM renames FM25v01.Driver;
   begin
      FRAM.Write_Byte (addr => FRAM.Address (variable), byte => data);
   end Store;
end NVRAM;
