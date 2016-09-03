--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors:     Emanuel Regnath (emanuel.regnath@tum.de)
with HAL;
with Interfaces; use Interfaces;
with Ada.Unchecked_Conversion;

--  @summary
--  target-independent functions of HIL.
package HIL with
   SPARK_Mode
is
   pragma Preelaborate;

   --procedure configure_Hardware;  
   subtype Byte is HAL.Byte;
   
   -- Unsigned_8
   -- Integer_8
   
   type Bit is mod 2**1 with Size => 1;
   

   -- Architecture Independent
   
   type Unsigned_8_Mask is new Unsigned_8;
   subtype Unsigned_8_Bit_Index is Natural range 0 .. 7;
   
   type Unsigned_16_Mask is new Unsigned_16;
   type Unsigned_16_Bit_Index is new Natural range 0 .. 15;
   
   type Unsigned_32_Mask is new Unsigned_32;
   type Unsigned_32_Bit_Index is new Natural range 0 .. 31;   
      
   
   -- Arrays
   type Byte_Array is array(Natural range <>) of Byte;
   type Short_Array is array(Natural range <>) of Unsigned_16;
   type Word_Array is array(Natural range <>) of Unsigned_32;


   subtype Byte_Array_2 is Byte_Array(1..2); -- not working (explicit raise in flow_utility.adb)

   -- type Byte_Array_2 is Byte_Array(1..2);
   type Byte_Array_4 is array(1..4) of Byte;



   type Unsigned_8_Array  is array(Natural range <>) of Unsigned_8;
   type Unsigned_16_Array is array(Natural range <>) of Unsigned_16;  
   type Unsigned_32_Array is array(Natural range <>) of Unsigned_32;   
   
   
   type Integer_8_Array  is array(Natural range <>) of Integer_8;
   type Integer_16_Array is array(Natural range <>) of Integer_16;
   type Integer_32_Array is array(Natural range <>) of Integer_32;
   
   
   type Float_Array is array(Natural range <>) of Float;


   function From_Byte_Array_To_Float is new Ada.Unchecked_Conversion (Source => Byte_Array_4,
                                                                           Target => Float); 
                                                                           
   function From_Float_To_Byte_Array is new Ada.Unchecked_Conversion (Source => Float,
                                                                           Target => Byte_Array_4); 

   -- little endian (lowest byte first)
   function toBytes(uint : in Unsigned_16) return Byte_Array is
     (1 => Unsigned_8( uint mod 2**8 ), 2 => Unsigned_8 ( uint / 2**8 ) );
   
   
      
   function toBytes( source : in Float) return Byte_Array_4 is
      (From_Float_To_Byte_Array( source ) )
   with Pre => source'Size = 32;

   -- FAILS  (unsigned arg, constrained return)
   function toBytes_uc(uint : Unsigned_16) return Byte_Array_2 is
      (1 => Unsigned_8( uint mod 2**8 ), 2 => Unsigned_8 ( uint / 2**8 ) );

   function toUnsigned_16( bytes : Byte_Array) return Unsigned_16
   is
      (Unsigned_16( bytes( bytes'First ) ) 
      + Unsigned_16( bytes( bytes'First + 1 ) ) * 2**8 )
   with Pre => bytes'Length = 2;
      
   function toUnsigned_32( bytes : Byte_Array) return Unsigned_32
   is
      (Unsigned_32( bytes( bytes'First ) ) + Unsigned_32( bytes'First + 1 ) * 2**8 + Unsigned_32( bytes'First + 2 ) * 2**16 + Unsigned_32( bytes'First + 3 ) * 2**24 )
   with Pre => bytes'Length = 4;

   function Bytes_To_Unsigned32 is new Ada.Unchecked_Conversion (Source => Byte_Array_4,
                                                                 Target => Unsigned_32); 
   
   function Unsigned32_To_Bytes is new Ada.Unchecked_Conversion (Source => Unsigned_32,
                                                     Target => Byte_Array_4);


   function From_Byte_To_Integer_8 is new Ada.Unchecked_Conversion (Source => Byte,
                                                                      Target => Integer_8);


   function From_Byte_Array_To_Integer_32 is new Ada.Unchecked_Conversion (Source => Byte_Array_4,
                                                                           Target => Integer_32);

   function toInteger_8( value : Byte ) return Integer_8 is
   ( From_Byte_To_Integer_8( value ) );


   function toInteger_32( bytes : Byte_Array) return Integer_32
   is
      (From_Byte_Array_To_Integer_32( Byte_Array_4( bytes ) ) )
   with Pre => bytes'Length = 4;


   function toCharacter( source : Byte ) return Character
   is ( Character'Val ( source ) );
   
   function toFloat( source : Byte_Array_4 ) return Float is
   ( From_Byte_Array_To_Float( source ) );


   procedure write_Bits( register : in out Unsigned_8; 
                         start_index : Unsigned_8_Bit_Index; 
                         length : Positive; 
                         value : Integer) with 
     Pre => length <= Natural (Unsigned_8_Bit_Index'Last) + 1 - Natural (start_index) and then
     value < 2**(length-1) + 2**(length-1) - 1; -- e.g. 2^8 = 256, but range is only up to 2^8-1
                         
   
   function read_Bits( register : in Unsigned_8; 
                        start_index : Unsigned_8_Bit_Index; 
                        length      : Positive) return Unsigned_8
   with Pre => length <= Natural (Unsigned_8_Bit_Index'Last) + 1 - Natural (start_index),
        Post => read_Bits'Result < 2**length;




--     procedure set_Bit( reg : in out Unsigned_16, bit : Unsigned_16_Bit_ID) is
--        mask : Unsigned_16_Mask 
      
   procedure set_Bits( register : in out Unsigned_16; bit_mask : Unsigned_16_Mask)
   with Pre => register'Size = bit_mask'Size;

   procedure clear_Bits( register : in out Unsigned_16; bit_mask : Unsigned_16_Mask)
   with Pre => register'Size = bit_mask'Size;
   
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
