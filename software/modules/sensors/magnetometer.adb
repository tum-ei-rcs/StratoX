with Generic_Sensor;
with HMC5883L.Driver; use HMC5883L;

with Units.Numerics; use Units.Numerics;

package body Magnetometer is

   -- Magnetometer_Sensor.Sensor_Signal(


   overriding procedure initialize (Self : in out Magnetometer_Tag) is
   begin
      Driver.init;
   end initialize;

   overriding procedure read_Measurement(Self : in out Magnetometer_Tag) is
   begin
      Driver.update_val;
      Self.sample.data.pressure := Driver.get_pressure;
      Self.sample.data.temperature := Driver.get_temperature;
   end read_Measurement;

   function get_Heading(Self : Magnetometer_Tag) return Heading_Type is
   begin
      return Self.sample.data.pressure;
   end get_Heading;

end Magnetometer;
