with Interfaces; use Interfaces;
with Bounded_Image; use Bounded_Image;

package body Units with SPARK_Mode is

   function average( signal : Unit_Array ) return Unit_Type is
      function Sat_Add_Unit is new Saturated_Addition (Unit_Type);
      avg : Unit_Type := 0.0;
   begin
      if signal'Length > 0 then
         for index in Integer range signal'First .. signal'Last loop
            avg := Sat_Add_Unit (avg, signal (index));
         end loop;
         avg := avg / Unit_Type (signal'Length);
      end if;
      return avg;
   end average;


   function Clip_Unitcircle (X : Unit_Type) return Unit_Type is
   begin
      if X < Unit_Type (-1.0) then
         return Unit_Type (-1.0);
      elsif X > Unit_Type (1.0) then
         return Unit_Type (1.0);
      end if;
      return X;
   end Clip_Unitcircle;


   --function wrap_Angle( angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type is
   -- ( Angle_Type'Remainder( (angle - min - (max-min)/2.0) , (max-min) ) + (max+min)/2.0 );
   function wrap_angle (angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type is
      span  : constant Angle_Type := max - min;
      d_flt : Float;
      d_int : Float;
      frac  : Float;
      less  : Angle_Type;
      wr    : Angle_Type;
      off   : Angle_Type;
      f64   : Interfaces.IEEE_Float_64;

      function Sat_Add_Angle is new Saturated_Addition (Angle_Type);
      function Sat_Sub_Angle is new Saturated_Subtraction (Angle_Type);
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
               wr := Sat_Sub_Angle (max, less);
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
               wr := Sat_Add_Angle (min, less);
            else
               wr := max;
            end if;
         end if;
      end if;
      return wr;
   end wrap_angle;




   function mirror_Angle( angle : Angle_Type; min : Angle_Type; max : Angle_Type) return Angle_Type is

      span : constant Angle_Type := max - min;
      cmax : constant Angle_Type := max + span / 2.0;
      cmin : constant Angle_Type := min - span / 2.0;
      --  limit to the ranges of wrap_angle's preconditions
      amax : constant Angle_Type := Angle_Type (if cmax < Angle_Type'Last / 2.0 then cmax else Angle_Type'Last / 2.0);
      amin : constant Angle_Type := Angle_Type (if cmin > Angle_Type'First / 2.0 then cmin else Angle_Type'First / 2.0);
      --pragma Assert (amin <= 0.0 * Radian);
      --pragma Assert (amax >= 0.0 * Radian);
      --pragma Assert (max > min);
      --pragma Assert (amin >= Angle_Type'First / 2.0);
      --pragma Assert (amax <= Angle_Type'Last / 2.0);
      wrapped : Angle_Type := wrap_angle (angle => angle, min => amin, max => amax);
      result : Angle_Type := wrapped;
   begin
      if wrapped > max then
         result := max - (wrapped - max);
      elsif wrapped < min then
         result := min - (wrapped - min);
      end if;
      return result;
   end mirror_Angle;



   function delta_Angle (From : Angle_Type; To : Angle_Type) return Angle_Type is
      function Sat_Sub_Flt is new Saturated_Subtraction (Float);
      diff : constant Float := Sat_Sub_Flt (Float (To), Float (From));
   begin
      return wrap_angle (angle => Angle_Type (diff), min => -180.0 * Degree, max => 180.0 * Degree);
   end delta_Angle;

   function Image (unit : Unit_Type) return String is
      first : constant Float  := Float'Truncation (Float (unit));
      rest  : constant String := Integer_Img (Integer ((Float (unit) - first) * Float(10.0)));
   begin
      if Float ( unit ) <  0.0 and -1.0 < Float ( unit ) then
         return "-" & Integer_Img (Types.Sat_Cast_Int (first)) & "." & rest (rest'Length);
      else
         return Integer_Img (Types.Sat_Cast_Int (first)) & "." & rest (rest'Length);
      end if;

   end Image;

   function AImage (unit : Angle_Type) return String is
   begin
      return Integer_Img (Types.Sat_Cast_Int (Float (unit) / Ada.Numerics.Pi * Float(180.0))) & "deg";
   end AImage;

   function RImage (unit : Angle_Type) return String is
   begin
      return " " & Image (Unit_Type(unit)) & "rad";
   end RImage;

   function Saturated_Cast (val : Float) return T is
      ret : T;
   begin
      if val > Float (T'Last) then
         ret := T'Last;
      elsif val < Float (T'First) then
         ret := T'First;
      else
         ret := T (val);
      end if;
      return ret;
   end Saturated_Cast;

   function Saturated_Addition (left, right : T) return T is
      ret : T;
   begin
      if right >= T (0.0) and then left >= (T'Last - right) then
         ret := T'Last;
      elsif right <= T (0.0) and then left <= (T'First - right) then
         ret := T'First;
      else
         declare
            cand : constant Float := Float (left) + Float (right); -- this needs to be constant and not a direct assignment to ret
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


   function Saturated_Subtraction (left, right : T) return T is
      ret : T;
   begin
      if right >= T (0.0) and then (right + T'First) >= left then
         ret := T'First;
      elsif right <= T (0.0) and then left >= (T'Last + right) then
         ret := T'Last;
      else
         declare
            cand : constant T := left - right; -- this needs to be constant and not a direct assignment to ret
         begin
            ret := cand;
         end;
      end if;
      return ret;
   end Saturated_Subtraction;


   function Wrapped_Addition (left, right : T) return T is
      cand : constant Float := Float (left) + Float (right);
      min  : constant T := T'First;
      max  : constant T := T'Last;
      span : constant Float := Float (max - min);

      d_flt : Float;
      d_int : Float;
      frac  : Float;
      less  : T;
      off   : Float;
      f64   : Interfaces.IEEE_Float_64;

      wr    : T;
   begin

      if span = 0.0 then
         --  this might happen due to float cancellation, despite precondition
         wr := min;
      else
         pragma Assert (span > 0.0);
         if cand >= Float (min) and cand <= Float (max) then
            wr := T (cand);
         elsif cand < Float (min) then
            off := (Float (min) - cand);
            d_flt := Float (off / span); -- overflow check might fail
            d_int := Float'Floor (d_flt);
            frac  := Float (d_flt - d_int);
            f64 := Interfaces.IEEE_Float_64 (frac) * Interfaces.IEEE_Float_64 (span);
            --pragma Assert (f64 >= 0.0);
            if f64 < Interfaces.IEEE_Float_64 (T'Last) and f64 >= Interfaces.IEEE_Float_64 (T'First) then
               less := T (f64); -- overflow check might fail
               wr := max - less;
            else
               wr := min;
            end if;
         else -- cand > max
            off := cand - Float (max);
            d_flt := Float (off / span); -- overflow check might fail
            d_int := Float'Floor (d_flt);
            frac  := Float (d_flt - d_int);
            pragma Assert (frac >= 0.0);
            f64 := Interfaces.IEEE_Float_64 (frac) * Interfaces.IEEE_Float_64 (span);
            --pragma Assert (f64 >= 0.0); -- this fails. why? both span and frac are positive
            if f64 > Interfaces.IEEE_Float_64 (T'First) and f64 < Interfaces.IEEE_Float_64 (T'Last) then
               less := T (f64);
               wr := min + less;
            else
               wr := max;
            end if;
         end if;
      end if;
      return wr;
   end Wrapped_Addition;

   function Saturate (val, min, max : T) return T is
      ret : T;
   begin
      if val < min then
         ret := min;
      elsif val > max then
         ret := max;
      else
         ret := val;
      end if;
      return ret;
   end Saturate;

end Units;
