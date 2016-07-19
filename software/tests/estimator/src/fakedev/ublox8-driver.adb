package body ublox8.driver with
SPARK_Mode,
Refined_State => (State => null) is
   procedure reset is null;

   procedure init is null;

   procedure update_val is null;
   -- read measurements values. Should be called periodically.

   function get_Position return GPS_Loacation_Type is
      a : GPS_Loacation_Type;
   begin
      return a;
   end;

   function get_GPS_Message return GPS_Message_Type is
      a : GPS_Message_Type;
   begin
      return a;
   end;

   function get_Fix return GPS_Fix_Type is
      a : GPS_FIX_Type;
   begin
      return a;
   end;

   -- function get_Direction return Direction_Type;

   procedure perform_Self_Check (Status : out Error_Type) is null;
end ublox8.driver;
