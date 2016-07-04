with Generic_Sensor;

with Units; use Units;
with MS5611.Driver; use MS5611;

package Barometer with SPARK_Mode is

   type Barometer_Data_Type is record
      pressure : Pressure_Type;
      temperature : Temperature_Type;
   end record;

   package Barometer_Sensor is new Generic_Sensor(Barometer_Data_Type); use Barometer_Sensor;

   type Barometer_Tag is new Barometer_Sensor.Sensor_Tag with record
      null;
   end record;

   overriding procedure initialize (Self : in out Barometer_Tag) with
   Global => (In_Out => (MS5611.Driver.State));

   overriding procedure read_Measurement(Self : in out Barometer_Tag)
   with Global => (In_Out => (MS5611.Driver.State, MS5611.Driver.Coefficients));

   function get_Pressure(Self : Barometer_Tag) return Pressure_Type;

   function get_Temperature(Self : Barometer_Tag) return Temperature_Type;

   function get_Altitude(Self : Barometer_Tag) return Length_Type;


   Sensor : Barometer_Tag;

private
   function Altitude(pressure : Pressure_Type) return Length_Type;

end Barometer;
