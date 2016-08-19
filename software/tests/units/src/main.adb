with Units; use Units;
with Units.Navigation; use Units.Navigation;
with Ada.Text_IO; use Ada.Text_IO;

procedure main is

   generic
      type T is digits <>;
   procedure Test_Wrap (STEP : T);
   --  adds all combinations of type T and prints the result to stdout

   procedure Test_Wrap (STEP : T) is
      l1, l2, lr : T;
      function Wrap_Add is new Wrapped_Addition (T => T);
   begin
      l1 := T'First;
      inc1 : loop
         l2 := T'First;
         inc2 : loop
            lr := Wrap_Add (l1, l2);
            Put_Line (Float (l1)'Img & ", " & Float (l2)'Img & " , " & Float (lr)'Img);

            exit inc2 when l2 >= T'Last - STEP;
            l2 := l2 + STEP;
         end loop inc2;

         delay 0.01;

         exit inc1 when l1 >= T'Last - STEP;
         l1 := l1 + STEP;
      end loop inc1;
   end Test_Wrap;

   procedure Test_Wrap_Lat is new Test_Wrap (T => Latitude_Type);
   procedure Test_Wrap_Lon is new Test_Wrap (T => Longitude_Type);
   procedure Test_Wrap_Alt is new Test_Wrap (T => Altitude_Type);

   STEP_LAT : constant Latitude_Type := 0.1 * Radian;
   STEP_LON : constant Longitude_Type := 0.1 * Radian;
   STEP_ALT : constant Altitude_Type := 100.0 * Meter;

begin

   Put_Line ("Latitude wrap:");
   Test_Wrap_Lat (STEP_LAT);
   Put_Line ("Longitude wrap:");
   Test_Wrap_Lon (STEP_LON);
   Put_Line ("Altitude wrap:");
   Test_Wrap_Alt (STEP_ALT);

end main;