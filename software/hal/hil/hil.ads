with HAL;
with Interfaces; use Interfaces;

package HIL is
   pragma Preelaborate;


   --procedure configure_Hardware;  
   -- type Byte is mod 2**8 with Size => 8;
   subtype Byte is HAL.Byte;
   
   type Unsigned_16_Mask is new Unsigned_16;
   type Unsigned_16_Bit_ID is new Natural range 0 .. 15;
   
   
   type Byte_Array is array(Natural range <>) of Byte;


   -- little endian (lowest byte first)
   function toBytes(uint : Unsigned_16) return Byte_Array is
      (1 => Unsigned_8( uint mod 2**8 ), 2 => Unsigned_8 ( uint / 2**8 ) );


   function toUnsigned_16( bytes : Byte_Array) return Unsigned_16 
   is
      (Unsigned_16( bytes(1) ) + Unsigned_16( bytes(2) ) * 2**8 )
   with pre => bytes'Length = 2;
      
   
--     procedure set_Bit( reg : in out Unsigned_16, bit : Unsigned_16_Bit_ID) is
--        mask : Unsigned_16_Mask 
      
   procedure set_Bits( register : in out Unsigned_16; bit_mask : Unsigned_16_Mask);

   procedure clear_Bits( register : in out Unsigned_16; bit_mask : Unsigned_16_Mask);
   
   function isSet( register : Unsigned_16; bit_mask : Unsigned_16_Mask) return Boolean is
      ( ( register and Unsigned_16( bit_mask ) ) > 0 );

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
