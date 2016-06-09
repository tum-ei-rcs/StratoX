


with Generic_Sensor;
with ublox8.Driver; use ublox8;


package body GPS is


   overriding procedure initialize (Self : in out GPS_Tag) is
   begin
      Driver.init;
   end initialize;

   overriding procedure read_Measurement(Self : in out GPS_Tag) is
   begin
      null;
   end read_Measurement;

   function get_Position(Self : GPS_Tag) return GPS_Data_Type is
   begin
      return Driver.get_Position;
   end get_Position;


end GPS;
