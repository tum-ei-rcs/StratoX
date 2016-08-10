with Generic_Sensor;

with Units; use Units;
with MS5611.Driver; use MS5611;

package Barometer with SPARK_Mode,
  Abstract_State => (States_Beyond_Sensor_Template)
is

   type Barometer_Data_Type is record
      pressure : Pressure_Type;
      temperature : Temperature_Type;
   end record;

--     function "+"(Left,Right : Barometer_Data_Type) return Barometer_Data_Type is
--     ( (pressure => Left.pressure + Right.pressure,
--          temperature => Left.temperature + Right.temperature) );
--
--     function "/"(Left : Barometer_Data_Type; Right : Float) return Barometer_Data_Type is
--     ( (pressure => Left.pressure / Right,
--          temperature => Left.temperature / Right) );


   package Barometer_Sensor is new Generic_Sensor(Barometer_Data_Type); use Barometer_Sensor;

   type Barometer_Tag is new Barometer_Sensor.Sensor_Tag with record
      null;
   end record;

   overriding procedure initialize (Self : in out Barometer_Tag)
     with Global => (Output => Barometer_Sensor.Sensor_State);
   --  with Global => (Output => MS5611.Driver.Coefficients, In_Out => (MS5611.Driver.State));

   overriding procedure read_Measurement(Self : in out Barometer_Tag)
     with Global => (In_Out => Barometer_Sensor.Sensor_State);
   --  with Global => (Input => MS5611.Driver.State, In_Out => (MS5611.Driver.Coefficients));

   function get_Pressure(Self : Barometer_Tag) return Pressure_Type;

   function get_Temperature(Self : Barometer_Tag) return Temperature_Type;

   function get_Altitude(Self : Barometer_Tag) return Length_Type;


   Sensor : Barometer_Tag;

private
   function Altitude(pressure : Pressure_Type) return Length_Type;

end Barometer;
