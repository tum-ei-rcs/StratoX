with Generic_Sensor;
with HMC5883L.Driver; use HMC5883L;

with Units.Numerics; use Units.Numerics;
with Interfaces; use Interfaces;
with Logger;

package body Magnetometer is

   -- Magnetometer_Sensor.Sensor_Signal(


   overriding procedure initialize (Self : in out Magnetometer_Tag) is
   begin
      Driver.initialize;
   end initialize;

   overriding procedure read_Measurement(Self : in out Magnetometer_Tag) is
      mag_x, mag_y, mag_z : Integer_16;
   begin
      null;
      --Driver.update_val;
      Driver.getHeading(mag_x, mag_y, mag_z);   -- are These Micro*Tesla?

      Logger.log(Logger.DEBUG, "Mag: " & Integer'Image(Integer(mag_x)) & ", "
                 & Integer'Image(Integer(mag_y)) & ", "
                 & Integer'Image(Integer(mag_z)) );

      Self.sample.data.magnetic_vector(X) := Unit_Type(mag_x) * Micro * Tesla;
      Self.sample.data.magnetic_vector(Y) := Unit_Type(mag_y) * Micro * Tesla;
      Self.sample.data.magnetic_vector(Z) := Unit_Type(mag_z) * Micro * Tesla;
      -- page 13/19: LSB/Gauss  230 .. 1370, 1090 default

      --Self.sample.data.heading := Heading(x, y, z);
   end read_Measurement;

   function get_Heading(Self : Magnetometer_Tag) return Heading_Type is
   begin
      return Self.sample.data.heading;
   end get_Heading;


   procedure compensateOrientation(Self : Magnetometer_Tag; orientation : Orientation_Type) is
   begin
      null;
   end compensateOrientation;


   function Heading(mag_vector : Magnetic_Flux_Density_Vector; orientation : Orientation_Type) return Heading_Type is
      mag_angle1 : Angle_Type := 0.0 * Degree;
      mag_length : Unit_Type := 0.0;
      temp_vector : Cartesian_Vector_Type := Cartesian_Vector_Type(mag_vector);
   begin

      rotate(temp_vector, Z, 45.0 * Degree);
      rotate(temp_vector, X, -orientation.Roll);
      rotate(temp_vector, Y, -orientation.Pitch);

         -- Arctan: Only X = Y = 0 raises exception
         -- Output range: -Cycle/2.0 to Cycle/2.0, thus -180° to 180°
         --mag_angle1  := Roll_Type ( Arctan( mag_vector(Z), mag_vector(Y) ) );

         --mag_length := Unit_Type( Sqrt( mag_vector(Y)**2 + mag_vector(Z)**2 ) );
         return Heading_Type ( Arctan( temp_vector(Y) , temp_vector(X), DEGREE_360 ) );
   end Heading;


end Magnetometer;
