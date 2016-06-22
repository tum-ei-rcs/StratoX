with Generic_Sensor;
with HMC5883L.Driver; use HMC5883L;

with Units.Numerics; use Units.Numerics;
with Interfaces; use Interfaces;

package body Magnetometer is

   -- Magnetometer_Sensor.Sensor_Signal(


   overriding procedure initialize (Self : in out Magnetometer_Tag) is
   begin
      Driver.initialize;
   end initialize;

   overriding procedure read_Measurement(Self : in out Magnetometer_Tag) is
      x,y,z : Integer_16;
   begin
      null;
      --Driver.update_val;
      Driver.getHeading(x, y, z);
      Self.sample.data.heading := Heading(x, y, z);
   end read_Measurement;

   function get_Heading(Self : Magnetometer_Tag) return Heading_Type is
   begin
      return Self.sample.data.heading;
   end get_Heading;


   function Heading(x : Integer_16; y : Integer_16; z : Integer_16) return Heading_Type is
      mag_angle1 : Angle_Type := 0.0 * Degree;
      mag_length : Float := 0.0;
   begin

         -- Arctan: Only X = Y = 0 raises exception
         -- Output range: -Cycle/2.0 to Cycle/2.0, thus -180° to 180°
         angle1  := Roll_Type ( Arctan( Float(-z), Float(x) ) );

         mag_length := Sqrt( Float(y)**2 + Float(z)**2 );
         return Heading_Type ( Arctan( mag_length , Float(X) ) + 180.0 );
   end Heading;


end Magnetometer;
