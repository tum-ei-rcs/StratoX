--  Institution: Technische Universität München
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--  Authors:     Martin Becker (becker@rcs.ei.tum.de)

with Ada.Real_Time; use Ada.Real_Time;
with HIL;           use HIL;

--  @summary
--  SPI protocol to CYPRESS FM25v0x series (ferroelectric RAM, non-volatile)
generic
   MEMSIZE_BYTES : Positive; -- FIXME: introduce datatype to constrain to 65kByte, beause we have 16bit addresses.
package FM25v0x with
   SPARK_Mode
   --  Abstract_State => State
is
   --MEMSIZE_BYTES : constant := Memory_Size;
   type Address is new Integer range 0 .. MEMSIZE_BYTES - 1;

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
private
   Is_Init : Boolean := False;-- with Part_Of => State;

   FM25v0x_STARTUP_TIME_MS : constant Time
     := Time_First + Milliseconds (1); -- datasheet: ~400 usec @3.3V

end FM25v0x;
