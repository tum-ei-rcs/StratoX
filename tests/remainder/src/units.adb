
with Ada.Text_IO; use Ada.Text_IO;
with Interfaces; use Interfaces;

package body units with SPARK_Mode is

   function wrap_angle2 (angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type is
      span : constant Angle_Type := max - min;
      d_flt : Float;
      d_int : Float;
      frac  : Float;
      less  : Angle_Type;
      wr    : Angle_Type;
      off   : Angle_Type;
      f64   : Interfaces.IEEE_Float_64;
   begin
      if span = Angle_Type (0.0) then
         --  this might happen due to float cancellation, despite precondition
         wr := min;
      else
         pragma Assert (span > Angle_Type (0.0));
         if angle >= min and angle <= max then
            wr := angle;
         elsif angle < min then
            off := (min - angle);
            d_flt := Float (off / span); -- overflow check might fail
            d_int := Float'Floor (d_flt);
            frac  := Float (d_flt - d_int);
            f64 := Interfaces.IEEE_Float_64 (frac) * Interfaces.IEEE_Float_64 (span);
            --pragma Assert (f64 >= 0.0);
            if f64 < Interfaces.IEEE_Float_64 (Angle_Type'Last) and f64 >= Interfaces.IEEE_Float_64 (Angle_Type'First) then
               less := Angle_Type (f64); -- overflow check might fail
               wr := max - less;
            else
               wr := min;
            end if;
         else -- angle > max
            off := angle - max;
            d_flt := Float (off / span); -- overflow check might fail
            d_int := Float'Floor (d_flt);
            frac  := Float (d_flt - d_int);
            pragma Assert (frac >= 0.0);
            f64 := Interfaces.IEEE_Float_64 (frac) * Interfaces.IEEE_Float_64 (span);
            --pragma Assert (f64 >= 0.0); -- this fails. why? both span and frac are positive
            if f64 > Interfaces.IEEE_Float_64 (Angle_Type'First) and f64 < Interfaces.IEEE_Float_64 (Angle_Type'Last) then
               less := Angle_Type (f64);
               wr := min + less;
            else
               wr := max;
            end if;
         end if;
      end if;
      return wr;
   end wrap_angle2;

end units;
