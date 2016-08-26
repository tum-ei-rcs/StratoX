with ublox8.Driver; use ublox8;
with Bounded_Image; use Bounded_Image;

package body GPS with SPARK_Mode,
  Refined_State => (State => (null))
is
   --overriding
   procedure initialize (Self : in out GPS_Tag) is
   begin
      Driver.init;
      Self.state := READY;
   end initialize;

   --overriding
   procedure read_Measurement(Self : in out GPS_Tag) is
      pragma Unreferenced (Self);
   begin
      Driver.update_val;
   end read_Measurement;

   function get_Position(Self : GPS_Tag) return GPS_Data_Type is
      pragma Unreferenced (Self);
   begin
      return Driver.get_Position;
   end get_Position;

   function get_GPS_Fix(Self : GPS_Tag) return GPS_Fix_Type is
      pragma Unreferenced (Self);
   begin
      return Driver.get_Fix;
   end get_GPS_Fix;

   function get_Speed(Self : GPS_Tag) return Units.Linear_Velocity_Type is
      pragma Unreferenced (Self);
   begin
      return Driver.get_Velo;
   end get_Speed;

   function get_Time(Self : GPS_Tag) return GPS_DateTime
   is
      pragma Unreferenced (Self);
   begin
      return Driver.get_Time;
   end get_Time;

   function get_Num_Sats(Self : GPS_Tag) return Unsigned_8 is
      pragma Unreferenced (Self);
   begin
      return Driver.get_Nsat;
   end get_Num_Sats;

   function Image (tm : GPS_DateTime) return String is
   begin
      return Natural_Img ( Natural (tm.year)) & "-" & Unsigned8_Img ( Unsigned_8 (tm.mon)) & "-" & Unsigned8_Img ( Unsigned_8 (tm.day)) & " "
        & Unsigned8_Img (Unsigned_8 (tm.hour)) & ":" & Unsigned8_Img ( Unsigned_8 (tm.min)) & ":" & Unsigned8_Img ( Unsigned_8 (tm.sec));
   end Image;

end GPS;
