
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
   package GPS_Buffer_Pack is new Generic_Queue(Index_Type => Height_Index_Type, Element_Type => GPS_Loacation_Type);

   G_height_buffer : Height_Buffer_Pack.Buffer_Type;
   G_pos_buffer : GPS_Buffer_Pack.Buffer_Type;


   type State_Type is record
      fix : GPS_Fix_Type := NO_FIX;
      avg_gps_height : Altitude_Type := 0.0 * Meter;
      max_gps_height : Altitude_Type := 0.0 * Meter;
      avg_baro_height : Altitude_Type := 0.0 * Meter;
      max_baro_height : Altitude_Type := 0.0 * Meter;
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
      G_state.max_gps_height := 0.0 * Meter;
      G_state.max_baro_height := 0.0 * Meter;

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
      GFixS : String := "NO";
   begin
      -- Estimate Object Orientation
      IMU.Sensor.read_Measurement;
      Acc := IMU.Sensor.get_Linear_Acceleration;

      Logger.log(Logger.TRACE,"Acc: " & Image(Acc(X)) & ", " & Image(Acc(Y)) & ", " & Image(Acc(Z)) );

      G_Object_Orientation := Orientation( Acc );

      Magnetometer.Sensor.read_Measurement;
      G_Object_Orientation.Yaw := Heading(Magnetometer.Sensor.get_Sample.data, G_Object_Orientation);


      -- Estimate Object Position
      Barometer.Sensor.read_Measurement; -- >= 4 calls for new data

      G_height_buffer.push_back( G_Object_Position.Altitude );
      update_Max_Height;


      GPS.Sensor.read_Measurement;
      G_state.fix := GPS.Sensor.get_GPS_Fix;
      -- FIXME: Sprung durch Baro Offset, falls GPS wegfällt
      if G_state.fix = FIX_3D then
         G_Object_Position := GPS.Sensor.get_Position;
         GFixS := "3D";
      elsif G_state.fix = FIX_2D then
         GFixS := "2D";
         G_Object_Position := GPS.Sensor.get_Position;
         G_Object_Position.Altitude := Barometer.Sensor.get_Altitude;  -- Overwrite Alt
      else
         GFixS := "NO";
         G_Object_Position.Altitude := Barometer.Sensor.get_Altitude;
      end if;
      G_pos_buffer.push_back( GPS.Sensor.get_Position );

      -- Outputs
      Logger.log(Logger.DEBUG,
                 "RPY: " & AImage( G_Object_Orientation.Roll ) &
                 ", " & AImage( G_Object_Orientation.Pitch ) &
                 ", " & AImage( G_Object_Orientation.Yaw ) );

      Logger.log(Logger.DEBUG,
                 "LG,LT,AL: " & AImage( G_Object_Position.Longitude ) &
                 ", " & AImage( G_Object_Position.Latitude ) &
                 ", " & Image( G_Object_Position.Altitude ) & "m, " & GFixS );

   end update;

   function get_Orientation return Orientation_Type is
   begin
      return G_Object_Orientation;
   end get_Orientation;

   function get_Position return GPS_Loacation_Type is
   begin
      return G_Object_Position;
   end get_Position;

   function get_GPS_Fix return GPS_Fix_Type is
   begin
      return G_state.fix;
   end get_GPS_Fix;


   function get_current_Height return Altitude_Type is
      result : Altitude_Type;
   begin
      if G_state.fix = FIX_3D then
         result := G_state.avg_gps_height;
      else
         result := G_state.avg_baro_height;
      end if;
      return result;
   end get_current_Height;

   function get_max_Height return Altitude_Type is
      result : Altitude_Type;
   begin
      if G_state.fix = FIX_3D then
         result := G_state.max_gps_height;
      else
         result := G_state.max_baro_height;
      end if;
      return result;
   end get_max_Height;








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

      function gps_average( signal : GPS_Buffer_Pack.Element_Array ) return Altitude_Type is
         avg : Altitude_Type;
      begin
         avg := signal( signal'First ).Altitude / Unit_Type( signal'Length );
         if signal'Length > 1 then
            for index in GPS_Buffer_Pack.Length_Type range 2 .. signal'Length loop
               avg := avg + signal( index ).Altitude / Unit_Type( signal'Length );
            end loop;
         end if;
         return avg;
      end gps_average;


      function baro_average( signal : Height_Buffer_Pack.Element_Array ) return Altitude_Type is
         avg : Altitude_Type;
      begin
         avg := signal( signal'First ) / Unit_Type( signal'Length );
         if signal'Length > 1 then
            for index in Height_Buffer_Pack.Length_Type range 2 .. signal'Length loop
               avg := avg + signal( index ) / Unit_Type( signal'Length );
            end loop;
         end if;
         return avg;
      end baro_average;
   begin
      -- GPS
      declare
         buf : GPS_Buffer_Pack.Element_Array(1 .. G_pos_buffer.Length);
      begin
         G_pos_buffer.get_all( buf );
         if G_pos_buffer.Length > 0 then
            G_state.avg_gps_height := gps_average( buf );
         end if;
      end;

      if G_state.avg_gps_height > G_state.max_gps_height then
         G_state.max_gps_height := G_state.avg_gps_height;
      end if;

      -- Baro
      declare
         buf : Height_Buffer_Pack.Element_Array(1 .. G_height_buffer.Length);
      begin
         G_height_buffer.get_all( buf );
         if G_height_buffer.Length > 0 then
            G_state.avg_baro_height := baro_average( buf );
         end if;
      end;

      if G_state.avg_baro_height > G_state.max_baro_height then
         G_state.max_baro_height := G_state.avg_baro_height;
      end if;

   end update_Max_Height;


end Estimator;
