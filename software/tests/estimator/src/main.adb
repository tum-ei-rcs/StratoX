with Estimator;
with Units.Navigation; use Units.Navigation;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Simulation;

with Units; use Units;
with Units.Vectors; use Units.Vectors;
with Kalman;


procedure main is


   subtype Elevon_Angle_Type   is Angle_Type range -45.0 * Degree .. 45.0 * Degree;

   type Elevon_Index_Type is (LEFT, RIGHT);

   type Elevon_Angle_Array is array(Elevon_Index_Type) of Elevon_Angle_Type;


   est_ort : Orientation_Type;
   est_loc : GPS_Loacation_Type;
   est_gfx : GPS_Fix_Type;
   est_calt : Altitude_Type;
   est_malt : Altitude_Type;

   outfile : File_Type;
   next : Ada.Real_Time.Time;

   Elevons : Elevon_Angle_Array := (0.0*Degree, 0.0*Degree);
   init_state : Kalman.State_Vector := Kalman.DEFAULT_INIT_STATES;

   procedure startfile is
   begin
      Put_Line (outfile, "time;roll;pitch;yaw;alt");
   end startfile;

   procedure write2file (o : Orientation_Type; a: Altitude_Type) is
      t : Float := Simulation.CSV_here.Get_Column ("time");
   begin
      Put_Line (outfile, t'img & ";" & Float (o.Roll)'img & ";" & Float (o.Pitch)'img & ";" & Float (o.Yaw)'img & ";" & Float (a)'Img);
   end write2file;

begin
   Simulation.init;
   Estimator.initialize;

   Create (File => outfile, Mode => Out_File, Name => "../estimate.csv");
   if not Is_Open (outfile) then
      Put_Line ("Error creating output file");
      return;
   end if;
   startfile;

   -- Initial States
   init_state.orientation.Roll := -50.0*Degree;
   init_state.orientation.Pitch := 70.0*Degree;
   init_state.rates(X) := Angular_Velocity_Type( Simulation.CSV_here.Get_Column ("gyroX") );
   init_state.rates(Y) := Angular_Velocity_Type( Simulation.CSV_here.Get_Column ("gyroY") );
   init_state.bias(X) := 2.0*Degree/Second;
   init_state.bias(Y) := 2.6*Degree/Second;
   Kalman.reset( init_state );
   Estimator.update( (0.0*Degree, 0.0*Degree) );



   next := Clock;
   Read_Loop :
   loop
      Simulation.update;
      exit Read_Loop when Simulation.Finished;


      -- Read Control Signals
      Elevons(LEFT) := Angle_Type( Simulation.CSV_here.Get_Column ("EleL") );
      Elevons(RIGHT) := Angle_Type( Simulation.CSV_here.Get_Column ("EleR") );


      Estimator.update( ( Elevons( RIGHT ) / 2.0 + Elevons( LEFT ) / 2.0,
                          Elevons( RIGHT ) / 2.0 - Elevons( LEFT ) / 2.0 ) );

      est_ort := Estimator.get_Orientation;
      est_loc := Estimator.get_Position;
      est_gfx := Estimator.get_GPS_Fix;
      est_calt := Estimator.get_current_Height;
      est_malt := Estimator.get_max_Height;

      -- log to file
      write2file (est_ort, est_calt);

      -- time to display output
      delay until next;
      next := next + Milliseconds (20);
   end loop Read_Loop;
   Simulation.close;
   Close (outfile);
end main;
