with Simulation;
with Ada.Text_IO; use Ada.Text_IO;
with Units; use Units;

package body ublox8.driver with
SPARK_Mode => Off,
Refined_State => (State => (null)) is


   cur_loc : GPS_Loacation_Type; -- L,L,A
   cur_msg : GPS_Message_Type;
   cur_fix : GPS_FIX_Type;

   procedure reset is null;

   procedure init is null;

   function get_Nsat return Unsigned_8 is ( 0 );

   procedure update_val is
   begin

      --cur_loc.Longitude := Longitude_Type ( Simulation.CSV_here.Get_Column ("Lng"));
      --cur_loc.Latitude := Latitude_Type (  Simulation.CSV_here.Get_Column ("Lat"));
      --cur_loc.Altitude := Altitude_Type (  Simulation.CSV_here.Get_Column ("Alt"));

      cur_fix := NO_FIX;-- GPS_Fix_Type'Enum_Val (Integer ( Simulation.CSV_here.Get_Column ("fix")));

      cur_msg.sats := Unsigned_8 ( 0 );
      cur_msg.speed := Linear_Velocity_Type ( 0.0 );

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
