with Interfaces; use Interfaces;

--  @summary
--  dummy file replacing hil.ads (because we don't want
--  its additional dependencies here)
package HIL with
   SPARK_Mode
is
   pragma Preelaborate;

   --  procedure configure_Hardware;
   type Byte is mod 2**8 with Size => 8;

   --  Arrays
   type Byte_Array is array (Natural range <>) of Byte;

end HIL;
