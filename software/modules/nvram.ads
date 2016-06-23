--  Institution: Technische Universität München
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--  Authors:     Martin Becker (becker@rcs.ei.tum.de)

with FM25v01.Driver;
with HIL;

--  @summary
--  read/write from/to a non-volatile location. Every "variable"
--  has one byte.
package NVRAM with SPARK_Mode,
   Abstract_State => Memory_State
is

   procedure Init;
   -- initialize this module and possibly underlying hardware

   procedure Self_Check (Status : out Boolean);
   -- check whether initialization was successful

   type Variable_Name is (VAR_MISSIONSTATE,
                          VAR_BOOTCOUNTER
                          --  add new variables here as needed
                         );

   procedure Load (variable : in Variable_Name; data : out HIL.Byte);
   -- read variable at given address and return value

   procedure Store (variable : in Variable_Name; data : in HIL.Byte);
   -- write variable to given address and return value

private
   subtype Address is FM25v01.Driver.Address;
end NVRAM;
