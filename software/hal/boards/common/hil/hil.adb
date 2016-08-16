--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)

--  @summary
--  target-independent functions of HIL.
package body HIL with
   SPARK_Mode => Off
is

   procedure set_Bits( register : in out Unsigned_16; bit_mask : Unsigned_16_Mask) is
   begin
      register := register or Unsigned_16( bit_mask );
   end set_Bits;

   procedure clear_Bits( register : in out Unsigned_16; bit_mask : Unsigned_16_Mask) is
   begin
      register := register and not Unsigned_16( bit_mask );
   end clear_Bits;

   procedure write_Bits( register : in out Unsigned_8;
                         start_index : Unsigned_8_Bit_Index;
                         length : Positive;
                         value : Integer) is
      bits_mask  : Unsigned_8 := (2**length - 1) * 2**Natural(start_index);
      value_mask : Unsigned_8 := Unsigned_8( value * 2**Natural(start_index) );
   begin
      register := (register and not bits_mask ) or (bits_mask or value_mask);
   end write_Bits;

   function read_Bits( register : in Unsigned_8;
                        start_index : Unsigned_8_Bit_Index;
                        length      : Positive) return Unsigned_8 is
      bits_mask  : Unsigned_8 := (2**length - 1) * 2**Natural(start_index);
      value : Unsigned_8 := (bits_mask and register) / 2**Natural(start_index);
   begin
      return value;
   end read_Bits;

end HIL;
