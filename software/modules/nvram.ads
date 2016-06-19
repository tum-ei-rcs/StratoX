-- Institution: Technische Universität München
-- Department:  Real-Time Computer Systems (RCS)
-- Project:     StratoX
-- Authors:     Martin Becker (becker@rcs.ei.tum.de)

with FM25v01.Driver;
with HIL;

-- @summary
-- read/write from/to a non-volatile location
--
-- FIXME: do something more clever. For now we
-- hardcoded the addresses of variables in NVRAM.
package NVRAM with SPARK_Mode is

   procedure Init;
   -- initialize this module and possibly underlying hardware

   procedure Self_Check (Status : out Boolean);
   -- check whether initialization was successful

   type Address is private; -- forces user to use following constants
                            -- and avoids instantiating this type
   VARIABLE_MISSIONSTATE : constant Address;
   VARIABLE_BOOTCOUNTER  : constant Address;

   procedure Load (variable : Address; data : out HIL.Byte);
   -- read variable at given address and return value

   procedure Store (variable : Address; data : in HIL.Byte);
   -- write variable to given address and return value

private
   type Address is new FM25v01.Driver.Address;

   -- hardcoded addresses, for now. Maybe later have a "register"
   -- function that generates addresses automatically.
   VARIABLE_MISSIONSTATE : constant Address := 0; -- 1 Byte
   VARIABLE_BOOTCOUNTER  : constant Address := 1; -- 1 Byte

end NVRAM;
