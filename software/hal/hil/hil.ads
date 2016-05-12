with HAL;

package HIL is
   pragma Preelaborate;


   --procedure configure_Hardware;  
   -- type Byte is mod 2**8 with Size => 8;
   subtype Byte is HAL.Byte;
   
   type Byte_Array is array(Natural range <>) of Byte;

end HIL;
