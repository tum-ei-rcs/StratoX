with HAL;
with Interfaces; use Interfaces;

package HIL is
   pragma Preelaborate;


   --procedure configure_Hardware;  
   -- type Byte is mod 2**8 with Size => 8;
   subtype Byte is HAL.Byte;
   
   type Byte_Array is array(Natural range <>) of Byte;



   function toBytes(uint : Unsigned_16) return Byte_Array is
      (1 => Unsigned_8 ( uint / 2**8 ), 2 => Unsigned_8( uint mod 2**8 ) );

--     procedure Read_Buffer
--        (Stream : not null access Streams.Root_Stream_Type'Class;
--         Item   : out Byte_Array);
--  
--     procedure Write_Buffer
--        (Stream : not null access Streams.Root_Stream_Type'Class;
--         Item   : in Byte_Array);
--  
--     for Byte_Array'Read  use Read_Buffer;
--     for Byte_Array'Write use Write_Buffer;

end HIL;
