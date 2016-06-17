

with IMU;
with GPS;
with Barometer;

with Units.Numerics; use Units.Numerics;

with Logger;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Estimator is


   Test : Translation_Vector := (0.0 * Meter, 0.0 * Meter, 0.0 * Meter);
   Foo  : Translation_Vector := (0.0 * Meter, 3.0 * Meter, 0.0 * Meter);


   -- init
   procedure initialize is
   begin
      Test := Test + Foo;

      IMU.Sensor.initialize;

      Barometer.Sensor.initialize;

      GPS.Sensor.initialize;

      Logger.log(Logger.INFO, "Estimator initialized");
   end initialize;

   -- fetch fresh measurement data
   procedure update is
      Sample : IMU.IMU_Sensor.Sample_Type;
      Acc : Linear_Acceleration_Vector;
   begin
      IMU.Sensor.read_Measurement;
      Sample := IMU.Sensor.get_Sample;
      Acc := IMU.Sensor.get_Linear_Acceleration;




      Logger.log(Logger.TRACE,
                 "Acc: " & Image( Acc(X) ) &
                 ", " & Image( Acc(Y) ) &
                 ", " & Image( Acc(Z) ) );

--                   " Gyr: " & Integer_16'Image( Acc.data.Gyro_X) &
--                   ", " & Integer_16'Image(Acc.data.Gyro_Y) &
--                   ", " & Integer_16'Image(Acc.data.Gyro_Z) );

      G_Object_Orientation := Orientation( Acc );
      Logger.log(Logger.TRACE,
                 "Rad: " & AImage( G_Object_Orientation.Roll ) &
                 ", " & AImage( G_Object_Orientation.Pitch ) &
                 ", " & AImage( G_Object_Orientation.Yaw ) );


      GPS.Sensor.read_Measurement;

   end update;


   function get_Orientation return Orientation_Type is
   begin
      return G_Object_Orientation;
   end get_Orientation;


   function get_Position return GPS_Loacation_Type is
   begin
      return G_Object_Position;
   end get_Position;


   function Orientation(gravity_vector : Linear_Acceleration_Vector) return Orientation_Type is
      angles : Orientation_Type;
      g_length : Float := 0.0;
   begin
      -- normalize vector


      -- check valid
      if gravity_vector(Y) = 0.0 * Meter / Second**2 and gravity_vector(Z) = 0.0 * Meter / Second**2 then
         angles.Roll := 0.0 * Degree;
         angles.Pitch := 0.0 * Degree;
         angles.Yaw := 0.0 * Degree;
      else

         -- Arctan: Only X = Y = 0 raises exception
         -- Output range: -Cycle/2.0 to Cycle/2.0, thus -180° to 180°
         angles.Roll  := Roll_Type ( Arctan(
                                     -gravity_vector(Z),
                                     gravity_vector(Y) ) );

         g_length := Sqrt( Float(gravity_vector(Y))**2 + Float(gravity_vector(Z))**2 );
         angles.Pitch := Pitch_Type ( Arctan( Linear_Acceleration_Type( g_length ) , gravity_vector(X) ) );
         angles.Yaw := 0.0 * Degree;

      end if;

      return angles;
   end Orientation;

end Estimator;
