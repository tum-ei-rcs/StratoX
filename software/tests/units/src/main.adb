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


   generic
      type T is digits <>;
   procedure Test_Sat_Sub (STEP : T);
   --  adds all combinations of type T and prints the result to stdout

   procedure Test_Sat_Sub (STEP : T) is
      l1, l2, lr : T;
      function Sat_Sub is new Saturated_Subtraction (T => T);
   begin
      l1 := T'First;
      inc1 : loop
         l2 := T'First;
         inc2 : loop
            lr := Sat_Sub (l1, l2);
            Put_Line (Float (l1)'Img & ", " & Float (l2)'Img & " , " & Float (lr)'Img);

            exit inc2 when l2 >= T'Last - STEP;
            l2 := l2 + STEP;
         end loop inc2;

         delay 0.01;

         exit inc1 when l1 >= T'Last - STEP;
         l1 := l1 + STEP;
      end loop inc1;
   end Test_Sat_Sub;

   generic
      type T is digits <>;
   procedure Test_Sat_Add (STEP : T);
   --  adds all combinations of type T and prints the result to stdout

   procedure Test_Sat_Add (STEP : T) is
      l1, l2, lr : T;
      function Sat_Add is new Saturated_Addition (T => T);
   begin
      l1 := T'First;
      inc1 : loop
         l2 := T'First;
         inc2 : loop
            lr := Sat_Add (l1, l2);
            Put_Line (Float (l1)'Img & ", " & Float (l2)'Img & " , " & Float (lr)'Img);

            exit inc2 when l2 >= T'Last - STEP;
            l2 := l2 + STEP;
         end loop inc2;

         delay 0.01;

         exit inc1 when l1 >= T'Last - STEP;
         l1 := l1 + STEP;
      end loop inc1;
   end Test_Sat_Add;

   procedure Test_Wrap_Lat is new Test_Wrap (T => Latitude_Type);
   procedure Test_Wrap_Lon is new Test_Wrap (T => Longitude_Type);
   procedure Test_Wrap_Alt is new Test_Wrap (T => Altitude_Type);

   procedure Test_Sat_Sub_Lat is new Test_Sat_Sub (T => Latitude_Type);
   procedure Test_Sat_Add_Lat is new Test_Sat_Add (T => Latitude_Type);

   STEP_LAT : constant Latitude_Type := 0.1 * Radian;
   STEP_LON : constant Longitude_Type := 0.1 * Radian;
   STEP_ALT : constant Altitude_Type := 100.0 * Meter;

begin

--     Put_Line ("Latitude wrap:");
--     Test_Wrap_Lat (STEP_LAT);
--  --     Put_Line ("Longitude wrap:");
--  --     Test_Wrap_Lon (STEP_LON);
--  --     Put_Line ("Altitude wrap:");
--  --     Test_Wrap_Alt (STEP_ALT);
--
--     Put_Line ("Latitude sat add:");
--     Test_Sat_Add_Lat (STEP_LAT);
--
--     Put_Line ("Latitude sat sub:");
--     Test_Sat_Sub_Lat (STEP_LAT);

   -- equivalence test of delta_angle
--     Put_Line ("Angle1, Angle2, Delta1, DeltaOld");
--     declare
--        subtype Heading_Type is Angle_Type range -360.0 * Degree .. 360.0 * Degree;
--        a1, a2 : Heading_Type;
--        da1, da2 : Float;
--        STEP : constant Heading_Type := 5.0 * Degree;
--     begin
--        a1 := Heading_Type'First;
--        inc1 : loop
--           a2 := Heading_Type'First;
--           inc2 : loop
--              da1 := Float (delta_Angle (From => a1, To => a2));
--              begin
--                 da2 := Float (delta_Angle_deprecated (From => a1, To => a2));
--              exception
--                 when others => da2 := -600.0;
--              end;
--              Put_Line (Float (a1)'Img & ", " & Float (a2)'Img & " , " & Float (da1)'Img & " , " & Float (da2)'Img);
--
--              exit inc2 when a2 >= Heading_Type'Last - STEP;
--              a2 := a2 + STEP;
--           end loop inc2;
--
--           delay 0.01;
--
--           exit inc1 when a1 >= Heading_Type'Last - STEP;
--           a1 := a1 + STEP;
--        end loop inc1;
--     end;

   Put_Line ("Distance test");
   declare

      function Head2Int (h : Heading_Type) return Integer is
         ret : Integer;
      begin
         ret := Integer (Float (h) * 180.0 / 3.14159);
         return ret;
      end Head2Int;

      s, t  : GPS_Loacation_Type;
      d : Length_Type;
      c : Heading_Type;
   begin
      s := (Latitude => 48.149825 * Degree, Longitude => 11.567860 * Degree, Altitude => 520.0 * Meter); -- TUM
      t := (Latitude => 48.138912 * Degree, Longitude => 11.572811 * Degree, Altitude => 520.0 * Meter); -- Frauenkirche
      d := Distance (source => s, target => t);
      c := Bearing (source_location => s, target_location => t);
      Put_Line ("TUM -> Frauenkirche: " & d'Img & " meter & compass=" & Head2Int (c)'Img); -- 1.3km

      s := (Latitude => 48.139618 * Degree, Longitude => 11.570907 * Degree, Altitude => 520.0 * Meter); -- TUM
      d := Distance (source => s, target => t);
      c := Bearing (source_location => s, target_location => t);
      Put_Line ("Frauenkirche -> Michaelskirche: " & d'Img & " meter & compass=" & Head2Int(c)'Img); -- 161m

      --  smoke test
      t := s;
      declare
         STEP : constant := 0.00003 * Degree;
         var : constant := 0.001 * Degree;
         lat_t : Latitude_Type;
         lon_t : Longitude_Type;
      begin
         lat_t := s.Latitude - Latitude_Type (var);
         inc1 : loop
            lon_t := s.Longitude - Longitude_Type (var);
            inc2 : loop

               t.Latitude := lat_t;
               t.Longitude := lon_t;
               d := Distance (s, t);
               c := Bearing (s, t);
               Put_Line ("S=" & Float(s.Latitude)'Img & "," & Float(s.Longitude)'Img  & ", T=" & Float(t.Latitude)'Img & ","
                         & Float(t.Longitude)'Img & " => d=" & Float (d)'Img & ", crs=" & Head2Int (c)'Img);

               exit inc2 when lon_t > s.Longitude + Longitude_Type (var);
               lon_t := lon_t + Longitude_Type (STEP);
            end loop inc2;

            delay 0.01;

            exit inc1 when lat_t > s.Latitude + Latitude_Type (var);
            lat_t := lat_t + Latitude_Type (STEP);
         end loop inc1;
      end;

   end;
end main;
