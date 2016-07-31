-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Driver for the GPS Module Ublox LEA-6H
--
-- ToDo:
-- [ ] Implementation


with Units.Navigation; use Units.Navigation;
with Units;
with HIL.UART;

package ublox8.Driver with
SPARK_Mode,
Abstract_State => State
is

   type Error_Type is (SUCCESS, FAILURE);

   subtype Time_Type is Units.Time_Type;


   type GPS_Message_Type is record
      year : Year_Type := 0;              --*< Year (UTC)
      month : Month_Type;            --*< Month, range 1..12 (UTC)
      day : Day_Of_Month_Type;       --*< Day of month, range 1..31 (UTC)
      hour : Hour_Type;              --*< Hour of day, range 0..23 (UTC)
      minute : Minute_Type;          --*< Minute of hour, range 0..59 (UTC)
      second : Second_Type;          --*< Seconds of minute, range 0..60 (UTC)
      fix : GPS_Fix_Type := NO_FIX;
      sats : Natural := 0;                --*< Number of SVs used in Nav Solution
      lon : Longitude_Type;
      lat : Latitude_Type;
      alt : Altitude_Type;
      speed : Units.Linear_Velocity_Type;
   end record;

   procedure reset;

   procedure init;

   procedure update_val;
   -- read measurements values. Should be called periodically.

   function get_Position return GPS_Loacation_Type;

   function get_GPS_Message return GPS_Message_Type;

   function get_Fix return GPS_Fix_Type;

   -- function get_Direction return Direction_Type;

   procedure perform_Self_Check (Status : out Error_Type);




private
   subtype Data_Type is HIL.UART.Data_Type;

end ublox8.Driver;
