package body Units is

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
