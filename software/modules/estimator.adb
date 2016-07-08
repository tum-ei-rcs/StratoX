
with Generic_Signal;
with Generic_Sensor;
with Generic_Queue;

with IMU;
with GPS;
with Barometer;
with Magnetometer;

with Units.Numerics; use Units.Numerics;

with Logger;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Estimator with SPARK_Mode is

   type Height_Index_Type is mod 10;

   package Height_Buffer_Pack is new Generic_Queue(Index_Type => Height_Index_Type, Element_Type => Altitude_Type);


   Test : Translation_Vector := (0.0 * Meter, 0.0 * Meter, 0.0 * Meter);
   Foo  : constant Translation_Vector := (0.0 * Meter, 3.0 * Meter, 0.0 * Meter);

   G_height_buffer : Height_Buffer_Pack.Ring_Buffer_Type;

   type State_Type is record
      pos_signal : GPS.GPS_Sensor.Sensor_Signal.Signal_Type( 1 .. 10 );
      max_height : Altitude_Type;
   end record;

   type Sensor_Record is record
      GPS1  : GPS.GPS_Tag;
      Baro1 : Barometer.Barometer_Tag;
      IMU1  : IMU.IMU_Tag;
      Mag1  : Magnetometer.Magnetometer_Tag;
   end record;

   -- type Sensor_Array is array(1 .. 2) of Generic_Sensor.Sensor_Tag;


   G_state  : State_Type;
   G_Sensor : Sensor_Record;
   -- G_Sensors : Sensor_Array;

   -- init
   procedure initialize is
   begin
      Test := Test + Foo;
      G_state.max_height := 0.0 * Meter;

      -- Orientation Sensors
      IMU.Sensor.initialize;
      Magnetometer.Sensor.initialize;

      -- Position Sensors
      Barometer.Sensor.initialize;
      GPS.Sensor.initialize;

      Logger.log(Logger.INFO, "Estimator initialized");
   end initialize;

   -- fetch fresh measurement data
   procedure update is
      Acc : Linear_Acceleration_Vector;
   begin
      -- Estimate Object Orientation
      IMU.Sensor.read_Measurement;
      Acc := IMU.Sensor.get_Linear_Acceleration;

      Logger.log(Logger.TRACE,
                 "Acc: " & Image( Acc(X) ) &
                 ", " & Image( Acc(Y) ) &
                 ", " & Image( Acc(Z) ) );

      G_Object_Orientation := Orientation( Acc );

      Magnetometer.Sensor.read_Measurement;
      G_Object_Orientation.Yaw := Heading(Magnetometer.Sensor.get_Sample.data, G_Object_Orientation);

      Logger.log(Logger.DEBUG,
                 "Rad: " & AImage( G_Object_Orientation.Roll ) &
                 ", " & AImage( G_Object_Orientation.Pitch ) &
                 ", " & AImage( G_Object_Orientation.Yaw ) );



      -- Estimate Object Position
      Barometer.Sensor.read_Measurement; -- >= 4 calls for new data
      G_Object_Position.Altitude := Barometer.Sensor.get_Altitude;
      G_height_buffer.push_back( G_Object_Position.Altitude );
      update_Max_Height;


      GPS.Sensor.read_Measurement;
      G_state.pos_signal(1).data := GPS.Sensor.get_Position;


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
                                     gravity_vector(Y),
                                     -gravity_vector(Z)
                                      ) );

         g_length := Sqrt( Float(gravity_vector(Y))**2 + Float(gravity_vector(Z))**2 );
         angles.Pitch := Pitch_Type ( Arctan( gravity_vector(X), Linear_Acceleration_Type( g_length ) ) );
         angles.Yaw := 0.0 * Degree;

      end if;

      return angles;
   end Orientation;

   procedure update_Max_Height is
      avg : Altitude_Type := 0.0 * Meter;
      buf : Height_Buffer_Pack.Element_Array(0 .. G_height_buffer.Length-1);

      function average( signal : Height_Buffer_Pack.Element_Array ) return Altitude_Type is
         avg : Altitude_Type;
      begin
         avg := signal( signal'First ) / Unit_Type( signal'Length );
         if signal'Length > 1 then
            for index in Natural range 0 .. G_height_buffer.Length-1 loop
               avg := avg + signal( index ) / Unit_Type( signal'Length );
            end loop;
         end if;
         return avg;
      end average;
   begin
      G_height_buffer.get_Buffer( buf );
      avg := average( buf );

      if avg > G_state.max_height then
         G_state.max_height := avg;
      end if;
   end update_Max_Height;

end Estimator;
