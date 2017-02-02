package body Generic_Types with SPARK_Mode is

   ------------------------
   --  Saturated_Cast_Int
   ------------------------

   function Saturated_Cast_Int (f : Float) return T is
      ret : T;
      ff : constant Float := Float'Floor (f);
   begin
      if ff >= Float (T'Last) then
         ret := T'Last;
      elsif ff < Float (T'First) then
         ret := T'First;
      else
         ret := T (ff);
      end if;
      return ret;
   end Saturated_Cast_Int;

   ------------------------
   --  Saturated_Cast_Mod
   ------------------------

   function Saturated_Cast_Mod (f : Float) return T is
      ret : T;
      ff : constant Float := Float'Floor (f);
   begin
      if ff >= Float (T'Last) then
         ret := T'Last;
      elsif ff < Float (T'First) then
         ret := T'First;
      else
         ret := T (ff);
      end if;
      return ret;
   end Saturated_Cast_Mod;

   ------------------
   --  Saturate_Mod
   ------------------

   function Saturate_Mod (val : T; min : T; max : T) return T is
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
   end Saturate_Mod;

end Generic_Types;
