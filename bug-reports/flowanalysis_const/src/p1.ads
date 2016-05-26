with Interfaces; use Interfaces;

package P1 with SPARK_Mode is

    type Byte_Array is array (Natural range <>) of Unsigned_8;

    function toBytes(uint : Unsigned_16) return Byte_Array is
      (1 => Unsigned_8( uint mod 2**8 ), 2 => Unsigned_8 ( uint / 2**8 ) );
end P1;
