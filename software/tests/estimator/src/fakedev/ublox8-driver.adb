with CSV;
with Simulation;
with Ada.Text_IO; use Ada.Text_IO;
with Units; use Units;

package body ublox8.driver with
SPARK_Mode => Off,
Refined_State => (State => (have_data, csv_file)) is

   package CSV_here is new CSV (filename => "ublox8.csv");
   have_data : Boolean := False;
   csv_file : File_Type;

   cur_loc : GPS_Loacation_Type; -- L,L,A
   cur_msg : GPS_Message_Type;
   cur_fix : GPS_FIX_Type;

   procedure reset is null;

   procedure init is
   begin
      if not CSV_here.Open then
         Put_Line ("Ublox8: Error opening file");
         Simulation.Finished := True;
         return;
      else
         Put_Line ("Ublox8: Replay from file");
         have_data := True;
         CSV_here.Parse_Header;
      end if;
   end init;

   procedure update_val is
   begin
      if not have_data and then CSV_here.End_Of_File then
         Simulation.Finished := True;
         Put_Line ("Ublox8: EOF");
         return;
      end if;

      if not csv_here.Parse_Row then
         Simulation.Finished := True;
         Put_Line ("Ublox8: Row error");
      end if;

      cur_loc.Longitude := Longitude_Type ( CSV_here.Get_Column ("lon"));
      cur_loc.Latitude := Latitude_Type ( CSV_here.Get_Column ("lat"));
      cur_loc.Altitude := Altitude_Type ( CSV_here.Get_Column ("alt"));

      cur_fix := GPS_Fix_Type'Enum_Val (Integer (CSV_here.Get_Column ("fix")));

      cur_msg.sats := Integer (CSV_here.Get_Column ("nsat"));
      cur_msg.speed := Linear_Velocity_Type (CSV_here.Get_Column ("speed"));

      -- don't care about the following for now:
      cur_msg.year := 2016;
      cur_msg.month := 07;
      cur_msg.day := 20;
      cur_msg.lat := cur_loc.Latitude;
      cur_msg.lon := cur_loc.Longitude;
      cur_msg.alt := cur_loc.Altitude;
      cur_msg.minute := 0;
      cur_msg.second := 0;
      cur_msg.hour := 0;
   end update_val;

   function get_Position return GPS_Loacation_Type is
   begin
      return cur_loc;
   end;

   function get_GPS_Message return GPS_Message_Type is
   begin
      return cur_msg;
   end;

   function get_Fix return GPS_Fix_Type is
   begin
      return cur_fix;
   end;

   -- function get_Direction return Direction_Type;

   procedure perform_Self_Check (Status : out Error_Type) is
   begin
      Status := SUCCESS;
   end perform_Self_Check;
end ublox8.driver;
