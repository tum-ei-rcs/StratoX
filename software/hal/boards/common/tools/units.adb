with Interfaces; use Interfaces;

package body Units is



--     procedure Saturate(input : Unit_Type; output : in out Unit_Type) is
--     begin
--        if input in output'Range then
--           output := input;
--        elsif input < output'First then
--           output := output'First;
--        else
--           output := output'Last;
--        end if;
--     end Saturate;

   function average( signal : Unit_Array ) return Unit_Type is
      avg : Unit_Type;
   begin
      avg := signal( signal'First ) / Unit_Type( signal'Length );
      if signal'Length > 1 then
         for index in Integer range signal'First+1 .. signal'Last loop
            avg := avg + signal( index ) / Unit_Type( signal'Length );
         end loop;
      end if;
      return avg;
   end average;

   -- idea: shift range to 0 .. X, wrap with mod, shift back
   --function wrap_Angle( angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type is
   -- ( Angle_Type'Remainder( (angle - min - (max-min)/2.0) , (max-min) ) + (max+min)/2.0 );
   function wrap_angle (angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type is
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
   end wrap_angle;




   function mirror_Angle( angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type is
      span : constant Angle_Type := max - min;
      wrapped : Angle_Type := wrap_angle( angle, min-span/2.0, max+span/2.0 );
      result : Angle_Type := wrapped;
   begin
      if wrapped > max then
         result := max - (wrapped - max);
      elsif wrapped < min then
         result := min - (wrapped - min);
      end if;
      return result;
   end mirror_Angle;



   function delta_Angle(From : Angle_Type; To : Angle_Type) return Angle_Type is
      result : Angle_Type := To - From;
   begin
      if result > 180.0 * Degree then
         result := result - 360.0 * Degree;
      elsif result < -180.0 * Degree then
         result := result + 360.0 * Degree;
      end if;
      return result;
   end delta_Angle;



   function Image (unit : Unit_Type) return String is
      first : constant Float  := Float'Truncation (Float (unit));
      rest  : constant String := Integer'Image (Integer ((Float (unit) - first) * Float(10.0)));
   begin
      if Float ( unit ) <  0.0 and -1.0 < Float ( unit ) then
         return "-" & Integer'Image (Integer (first)) & "." & rest (rest'Length);
      else
         return Integer'Image (Integer (first)) & "." & rest (rest'Length);
      end if;

   end Image;

   function AImage (unit : Angle_Type) return String is
   begin
      return Integer'Image (Integer (Float (unit) / Ada.Numerics.Pi * Float(180.0))) & "°";
   end AImage;

   function RImage (unit : Angle_Type) return String is
   begin
      return Image(Unit_Type(unit)) & "rad";
   end RImage;

   function Saturated_Addition (left, right : T) return T is
      ret : T := left;
   begin
--        if right > T (0.0) and then ret > (T'Last - right) + T'Small then
--           ret := T'Last;
--        elsif right < T (0.0) and then ret < (T'First - right) - T'Small then
--           ret := T'First;
--        else
      if True then
         declare
            cand : constant Float := Float (ret) + Float (right);
         begin
            --  range check
            if cand > Float (T'Last) then
               ret := T'Last;
            elsif cand < Float (T'First) then
               ret := T'First;
            else
               ret := T (cand);
            end if;
         end;
      end if;
      return ret;
   end Saturated_Addition;

end Units;
