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




   function Image (unit : Linear_Acceleration_Type) return String is
      first : constant Float  := Float'Truncation (Float (unit));
      rest  : constant String := Integer'Image (Integer ((Float (unit) - first) * 10.0));
   begin
      return Integer'Image (Integer (first)) & "." & rest (rest'Length);
   end Image;

   function AImage (unit : Angle_Type) return String is
   begin
      return Integer'Image (Integer (Float (unit) / Ada.Numerics.Pi * 180.0)) & "°";
   end AImage;

end Units;
