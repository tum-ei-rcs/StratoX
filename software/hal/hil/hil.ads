with HAL;
with Interfaces; use Interfaces;

package HIL with
   SPARK_Mode
is
   pragma Preelaborate;


   --procedure configure_Hardware;  
   -- type Byte is mod 2**8 with Size => 8;
   subtype Byte is HAL.Byte;
   
   -- Unsigned_8
   -- Integer_8
   
   
   type Unsigned_8_Mask is new Unsigned_8;
   type Unsigned_8_Index is new Natural range 0 .. 7;  
   
   type Unsigned_16_Mask is new Unsigned_16;
   type Unsigned_16_Bit_ID is new Natural range 0 .. 15;
   
   type Unsigned_32_Mask is new Unsigned_32;
   type Unsigned_32_Bit_ID is new Natural range 0 .. 31;   
   
   
   subtype Byte_Bit_Position is Integer range 0 .. 7;
   
   
   -- Arrays
   type Byte_Array is array(Natural range <>) of Byte;

   --subtype Byte_Array_2 is Byte_Array(1..2); -- not working (explicit raise in flow_utility.adb)

   type Byte_Array_2 is array(1..2) of Byte;
   
   type Unsigned_8_Array  is array(Natural range <>) of Unsigned_8;
   type Unsigned_16_Array is array(Natural range <>) of Unsigned_16;  
   type Unsigned_32_Array is array(Natural range <>) of Unsigned_32;   
   
   type Integer_8_Array  is array(Natural range <>) of Integer_8;
   type Integer_16_Array is array(Natural range <>) of Integer_16;
   type Integer_32_Array is array(Natural range <>) of Integer_32;
   
   
   type Float_Array is array(Natural range <>) of Float;


   -- little endian (lowest byte first)
   -- FAILS  (unsigned arg, unconstrained return)
   function toBytes(uint : in Unsigned_16) return Byte_Array is
      (1 => Unsigned_8( uint mod 2**8 ), 2 => Unsigned_8 ( uint / 2**8 ) );

   -- FAILS  (unsigned arg, constrained return)
   function toBytes_uc(uint : Unsigned_16) return Byte_Array_2 is
      (1 => Unsigned_8( uint mod 2**8 ), 2 => Unsigned_8 ( uint / 2**8 ) );

   function toUnsigned_16( bytes : Byte_Array) return Unsigned_16
   is
      (Unsigned_16( bytes( bytes'First ) ) 
      + Unsigned_16( bytes'First + 1 ) * 2**8 )
   with pre => bytes'Length = 2;
      

   function toUnsigned_32( bytes : Byte_Array) return Unsigned_32
   is
      (Unsigned_32( bytes( bytes'First ) ) + Unsigned_32( bytes'First + 1 ) * 2**8 + Unsigned_32( bytes'First + 2 ) * 2**16 + Unsigned_32( bytes'First + 3 ) * 2**24 )
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
