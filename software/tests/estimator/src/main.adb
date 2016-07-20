with Estimator;
with Units.Navigation; use Units.Navigation;
with Ada.Text_IO; use Ada.Text_IO;
with Simulation;

procedure main is
   est_ort : Orientation_Type;
   est_loc : GPS_Loacation_Type;
   est_gfx : GPS_Fix_Type;
   est_calt : Altitude_Type;
   est_malt : Altitude_Type;

begin
   Estimator.initialize;

   Read_Loop :
   loop

      exit Read_Loop when Simulation.Finished;
      Estimator.update;
--        est_ort := Estimator.get_Orientation;
--        est_loc := Estimator.get_Position;
      est_gfx := Estimator.get_GPS_Fix;
--        est_calt := Estimator.get_current_Height;
--        est_malt := Estimator.get_max_Height;
      delay (0.1);
   end loop Read_Loop;
end main;
