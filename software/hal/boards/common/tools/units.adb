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
