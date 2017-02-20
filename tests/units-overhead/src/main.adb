with Units; use Units;
--with Altunits; use Altunits;
with Ada.Text_IO; use Ada.Text_IO;

procedure main is

   a : Length_Type := 5.0;
   b : Time_Type := 2.0;
   v : Linear_Velocity_Type := 3.0;
   --v : Linear_Velocity_Type := 3.0;

   function calc_my_velocity( l : Length_Type; t : Time_Type ) return Linear_Velocity_Type is
   begin
      return l / t;
   end calc_my_velocity;


begin

   v := calc_my_velocity( a, a );

   Put_Line("Test");


end main;


-- with Dim_Sys: 522383

-- without Dim_Sys: 523132


