with Generic_Sensor;
with HMC5883L.Driver; use HMC5883L;
with HMC5883L.Register;

with Units.Numerics; use Units.Numerics;
with Interfaces; use Interfaces;
with Logger;

package body Magnetometer is


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

      Logger.log(Logger.TRACE, "Mag: " & Integer'Image(Integer(mag_x)) & ", "
                 & Integer'Image(Integer(mag_y)) & ", "
                 & Integer'Image(Integer(mag_z)) );

      Self.sample.data(X) := Unit_Type(mag_x) * Micro * Tesla;
      Self.sample.data(Y) := Unit_Type(mag_y) * Micro * Tesla;
      Self.sample.data(Z) := Unit_Type(mag_z) * Micro * Tesla;
      -- page 13/19: LSB/Gauss  230 .. 1370, 1090 default

      -- New Measurement
      Driver.setMode( Register.HMC5883L_MODE_SINGLE );
      -- Self.sample.data.heading := Heading(Self.sample.data.magnetic_vector, );
   end read_Measurement;




end Magnetometer;
