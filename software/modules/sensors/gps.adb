with ublox8; use ublox8;

package body GPS with SPARK_Mode
is


   overriding procedure initialize (Self : in out GPS_Tag) is
   pragma Unreferenced (Self);
   begin
      Driver.init;
   end initialize;

   overriding procedure read_Measurement(Self : in out GPS_Tag) is
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


end GPS;
