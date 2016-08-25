package body Types with SPARK_Mode is

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

end Types;
