with Ada.Text_IO; use Ada.Text_IO;
with Ada.Float_Text_IO;
with Units; use Units;

procedure main with SPARK_Mode is

   a : Angle_Type;
   w  : Angle_Type;
   w2 : Angle_Type;
   amin : constant Angle_Type := -1.3 * Radian;
   amax : constant Angle_Type := 1.3 * Radian;
   L    : constant Angle_Type := 2.0 * (amax - amin);
   STEPS : constant := 10_000;
   step : constant Angle_Type := L / 10_000.0;

begin
   a := 1.5 * amin;
   for k in 1 .. STEPS loop
      a := a + step;
      w := wrap_Angle (angle => a, min => amin, max => amax);
      w2 := wrap_Angle2 (angle => a, min => amin, max => amax);
      Ada.Float_Text_IO.Put (Item => Float (a), Aft => 3, Exp => 0);
      Put (",");
      Ada.Float_Text_IO.Put (Item => Float (w), Aft => 3, Exp => 0);
      Put (",");
      Ada.Float_Text_IO.Put (Item => Float (w2), Aft => 3, Exp => 0);
      declare
         err : constant Angle_Type := w2 - w;
      begin
         Put (",");
         Ada.Float_Text_IO.Put (Item => Float (err), Aft => 3, Exp => 0);
      end;
      New_Line;
   end loop;
end main;
