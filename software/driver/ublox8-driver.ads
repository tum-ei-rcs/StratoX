-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)

with Units.Navigation; use Units.Navigation;
with Units;
with HIL.UART;
with Interfaces; use Interfaces;

--  @summary Driver to parse messages of the GPS Module Ublox LEA-6H
package ublox8.Driver with SPARK_Mode,
  Abstract_State => State,
  Initializes => State
is

   type Error_Type is (SUCCESS, FAILURE);

   subtype Time_Type is Units.Time_Type;

   type GPS_DateTime_Type is record
      year : Year_Type := Year_Type'First;
      mon  : Month_Type := Month_Type'First;
      day  : Day_Of_Month_Type := Day_Of_Month_Type'First;
      hour : Hour_Type := Hour_Type'First;
      min  : Minute_Type := Minute_Type'First;
      sec  : Second_Type := Second_Type'First;
   end record;

   type GPS_Message_Type is record
      itow : GPS_Time_Of_Week_Type := 0;
      datetime : GPS_DateTime_Type;
      fix : GPS_Fix_Type := NO_FIX;
      sats : Unsigned_8 := 0;                         --*< Number of SVs used in Nav Solution
      lon : Longitude_Type;
      lat : Latitude_Type;
      alt : Altitude_Type;
      speed : Units.Linear_Velocity_Type;
   end record;

   procedure reset;

   procedure init;

   procedure update_val;
   --  poll raw data. Should be called periodically.

   function get_Position return GPS_Loacation_Type;
   --  read most recent position

   function get_GPS_Message return GPS_Message_Type;

   function get_Fix return GPS_Fix_Type;
   --  read most recent fix status

   function get_Nsat return Unsigned_8;
   --  read most recent number of used satellits

   function get_Velo return Units.Linear_Velocity_Type;
   --  read most recent velocity

   function get_Time return GPS_DateTime_Type;
   --  read most recent time stamp

   procedure perform_Self_Check (Status : out Error_Type);
   --  test communication with GPS (ignoring fix state)

private
   subtype Data_Type is HIL.UART.Data_Type;

end ublox8.Driver;
