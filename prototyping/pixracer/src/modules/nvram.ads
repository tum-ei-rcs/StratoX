--  Institution: Technische Universität München
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--  Authors:     Martin Becker (becker@rcs.ei.tum.de)

with HIL;
with HIL.NVRAM;

--  @summary
--  read/write from/to a non-volatile location. Every "variable"
--  has one byte.
package NVRAM with SPARK_Mode,
   Abstract_State => Memory_State
is

   procedure Init;
   --  initialize this module and possibly underlying hardware

   procedure Self_Check (Status : out Boolean);
   --  check whether initialization was successful

   --  List of all variables stored in NVRAM. Add as needed.
   type Variable_Name is (VAR_MISSIONSTATE,
                          VAR_BOOTCOUNTER);

   --  Default values for all variables
   type Defaults_Table is array (Variable_Name'Range) of HIL.Byte;
   Variable_Defaults : constant Defaults_Table :=
     (VAR_MISSIONSTATE => 0,
      VAR_BOOTCOUNTER  => 0);

   procedure Load (variable : in Variable_Name; data : out HIL.Byte);
   --  read variable at given address and return value

   procedure Store (variable : in Variable_Name; data : in HIL.Byte);
   --  write variable to given address and return value

end NVRAM;
