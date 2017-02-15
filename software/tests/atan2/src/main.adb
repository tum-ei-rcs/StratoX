with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

procedure main with SPARK_Mode is

   Y, X, angle : Float;

   dt : constant Float := 0.5;
begin
   for kx in Integer range -10 .. 10 loop
      X := Float(kx) * dt;
      for ky in Integer range -10 .. 10 loop
         Y := Float(ky) * dt;
         if X /= 0.0 or Y /= 0.0 then
            angle := Arctan (Y => Y, X => X);
            Put_Line (Y'Img & "," & X'Img & "," & angle'Img);
         end if;
      end loop;
   end loop;
end main;
