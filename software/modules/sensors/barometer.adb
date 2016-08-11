with Units.Numerics; use Units.Numerics;
with MS5611.Driver; use MS5611;

package body Barometer with SPARK_Mode,
  Refined_State => (States_Beyond_Sensor_Template => null)
is

   --overriding
   procedure initialize (Self : in out Barometer_Tag) is
   begin
      Driver.Init;
      Self.state := READY;
   end initialize;

   --overriding
   procedure read_Measurement(Self : in out Barometer_Tag) is
   begin
      Driver.Update_Val;
      Self.sample.data.pressure := Driver.Get_Pressure;
      Self.sample.data.temperature := Driver.Get_Temperature;
   end read_Measurement;

   function get_Pressure(Self : Barometer_Tag) return Pressure_Type is
   begin
      return Self.sample.data.pressure;
   end get_Pressure;

   function get_Temperature(Self : Barometer_Tag) return Temperature_Type is
   begin
      return Self.sample.data.temperature;
   end get_Temperature;


   -- international altitude equation
   function Altitude(pressure : Pressure_Type) return Length_Type is
      subtype Temperature_Gradient_Type is Unit_Type with
      Dimension => (Kelvin => 1, Meter => -1, others => 0);
      t_ref   : constant Temperature_Type := 288.15 * Kelvin;
      t_coeff : constant Temperature_Gradient_Type := 6.5 * Milli * Kelvin / Meter;
      p_ref   : constant Pressure_Type := 1013.25 * Hecto * Pascal;
      exp_frac  : constant Float := 1.0 / 5.255;
      h0   : constant Length_Type := t_ref / t_coeff;
      prel : constant Unit_Type := pressure / p_ref;
      comp : constant Unit_Type := prel**exp_frac;
      neg  : constant Unit_Type := 1.0 - comp; -- FIXME: overflow check might fail
   begin
      return h0 * neg; -- FIXME: overflow check might fail
   end Altitude;

   function get_Altitude(Self : Barometer_Tag) return Length_Type is
   begin
      return Altitude(Self.sample.data.pressure);
   end get_Altitude;
end Barometer;
