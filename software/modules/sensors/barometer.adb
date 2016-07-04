with MS5611.Driver; use MS5611;

with Units.Numerics; use Units.Numerics;

package body Barometer is

   -- Barometer_Sensor.Sensor_Signal(


   overriding procedure initialize (Self : in out Barometer_Tag) is
   begin
      Driver.init;
   end initialize;

   overriding procedure read_Measurement(Self : in out Barometer_Tag) is
   begin
      Driver.update_val;
      Self.sample.data.pressure := Driver.get_pressure;
      Self.sample.data.temperature := Driver.get_temperature;
   end read_Measurement;

   function get_Pressure(Self : Barometer_Tag) return Pressure_Type is
   begin
      return Self.sample.data.pressure;
   end get_Pressure;

   function get_Temperature(Self : Barometer_Tag) return Temperature_Type is
   begin
      return Self.sample.data.temperature;
   end get_Temperature;

   function get_Altitude(Self : Barometer_Tag) return Length_Type is
   begin
      return Altitude(Self.sample.data.pressure);
   end get_Altitude;

   -- international altitude equation
   function Altitude(pressure : Pressure_Type) return Length_Type is
      subtype Temperature_Gradient_Type is Unit_Type with
      Dimension => (Kelvin => 1, Meter => -1, others => 0);
      t_ref   : constant Temperature_Type := 288.15 * Kelvin;
      t_coeff : constant Temperature_Gradient_Type := 6.5 * Milli * Kelvin / Meter;
      p_ref   : constant Pressure_Type := 1013.25 * Hecto * Pascal;
      exp_frac  : constant Float := 1.0 / 5.255;
   begin
      return (t_ref / t_coeff) * ( 1.0 - (pressure / p_ref)**exp_frac );
   end Altitude;

end Barometer;
