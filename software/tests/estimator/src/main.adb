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

   outfile : File_Type;

   procedure startfile is
   begin
      Put_Line (outfile, "time;roll;pitch;yaw");
   end startfile;

   procedure write2file (o : Orientation_Type) is
      t : Float := Simulation.CSV_here.Get_Column ("time");
   begin
      Put_Line (outfile, t'img & ";" & Float (o.Roll)'img & ";" & Float (o.Pitch)'img & ";" & Float (o.Yaw)'img);
   end write2file;

   type prescaler is mod 10;
   k : prescaler := 0;
begin
   Simulation.init;
   Estimator.initialize;

   Create (File => outfile, Mode => Out_File, Name => "estimate.csv");
   if not Is_Open (outfile) then
      Put_Line ("Error creating output file");
      return;
   end if;
   startfile;

   Read_Loop :
   loop
      Simulation.update;
      exit Read_Loop when Simulation.Finished;

      Estimator.update;

      est_ort := Estimator.get_Orientation;
      est_loc := Estimator.get_Position;
      est_gfx := Estimator.get_GPS_Fix;
      est_calt := Estimator.get_current_Height;
      est_malt := Estimator.get_max_Height;

      -- TODO: log to file
      write2file (est_ort);

      -- time to display output
      if k = 0 then
         delay (0.01);
      end if;
      k := k + 1;
   end loop Read_Loop;
   Simulation.close;
   Close (outfile);
end main;
