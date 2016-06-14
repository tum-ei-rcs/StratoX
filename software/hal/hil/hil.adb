

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

end HIL;
