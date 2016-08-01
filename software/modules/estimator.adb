
with Generic_Signal;
--with Generic_Sensor;
with Generic_Queue;

with Ada.Real_Time; use Ada.Real_Time;

with IMU;
with GPS;
with Barometer;
with Magnetometer;

with Units.Numerics; use Units.Numerics;
with Units.Navigation; use Units.Navigation;

with Logger;
with Profiler;

with Config.Software;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

pragma Elaborate_All(generic_queue);

package body Estimator with SPARK_Mode is

   type Height_Index_Type is mod 10;
   type IMU_Index_Type is mod 10;
   type Baro_Call_Type is mod 2;
   type Logger_Call_Type is mod Config.Software.CFG_LOGGER_CALL_SKIP;

   package Height_Buffer_Pack is new Generic_Queue(Index_Type => Height_Index_Type, Element_Type => Altitude_Type);
   use Height_Buffer_Pack;
   package GPS_Buffer_Pack is new Generic_Queue(Index_Type => Height_Index_Type, Element_Type => GPS_Loacation_Type);
   use GPS_Buffer_Pack;
   package IMU_Buffer_Pack is new Generic_Queue(Index_Type => IMU_Index_Type, Element_Type => Orientation_Type);
   use IMU_Buffer_Pack;

   G_height_buffer : Height_Buffer_Pack.Buffer_Tag;
   G_pos_buffer : GPS_Buffer_Pack.Buffer_Tag;

   G_orientation_buffer : IMU_Buffer_Pack.Buffer_Tag;

   G_Profiler : Profiler.Profile_Tag;


   type State_Type is record
      fix : GPS_Fix_Type := NO_FIX;
      avg_gps_height : Altitude_Type := 0.0 * Meter;
      max_gps_height : Altitude_Type := 0.0 * Meter;
      avg_baro_height : Altitude_Type := 0.0 * Meter;
      max_baro_height : Altitude_Type := 0.0 * Meter;
      baro_calls : Baro_Call_Type := 0;
      logger_calls : Logger_Call_Type := 0;
      stable_Time     : Time_Type := 0.0 * Second;
      last_stable_check : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
   end record;

   type Sensor_Record is record
      GPS1  : GPS.GPS_Tag;
      Baro1 : Barometer.Barometer_Tag;
      IMU1  : IMU.IMU_Tag;
      Mag1  : Magnetometer.Magnetometer_Tag;
   end record;


   G_state  : State_Type;
   -- G_Sensor : Sensor_Record;


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

      -- Profiler
      G_Profiler.init("Estimator");

      Logger.log_console(Logger.INFO, "Estimator initialized");
   end initialize;

   -- fetch fresh measurement data
   procedure update is
      Acc : Linear_Acceleration_Vector;
      Gyro : Angular_Velocity_Vector;
      Acc_Orientation : Orientation_Type;
      CF_Orientation : Orientation_Type;
      Mag : Magnetic_Flux_Density_Vector;
      GFixS : String := "NO";

   begin
      G_Profiler.start;

      -- Estimate Object Orientation
      IMU.Sensor.read_Measurement;
      Acc := IMU.Sensor.get_Linear_Acceleration;
      Gyro := IMU.Sensor.get_Angular_Velocity;

     -- Logger.log_console(Logger.DEBUG,"Acc: " & Image(Acc(X)) & ", " & Image(Acc(Y)) & ", " & Image(Acc(Z)) );
      -- Logger.log_console(Logger.DEBUG,"Gyro: " & AImage(Gyro(Roll)*Second) & ", " & AImage(Gyro(Pitch)*Second) & ", " & AImage(Gyro(YAW)*Second) );
      -- Logger.log_console(Logger.DEBUG,"Gyro: " & RImage(Gyro(Roll)*Second) & ", " & RImage(Gyro(Pitch)*Second) & ", " & RImage(Gyro(YAW)*Second) );


      Acc_Orientation := Orientation( Acc );
      -- CF_Orientation := IMU.Fused_Orientation( IMU.Sensor, Acc_Orientation, Gyro);
      IMU.perform_Kalman_Filtering( IMU.Sensor, Acc_Orientation );
      G_Object_Orientation := IMU.Sensor.get_Orientation;


      -- Logger.log_console(Logger.INFO, "RPY: " & AImage( Acc_Orientation.Roll ) & ", " & AImage( Acc_Orientation.Pitch ) & ", " & AImage( Acc_Orientation.Yaw ) );
      -- Logger.log_console(Logger.INFO, "CF : " & AImage( CF_Orientation.Roll ) & ", " & AImage( CF_Orientation.Pitch ) & ", " & AImage( CF_Orientation.Yaw ) );
      -- Logger.log_console(Logger.INFO, "KM : " & AImage( G_Object_Orientation.Roll ) & ", " & AImage( G_Object_Orientation.Pitch ) & ", " & AImage( G_Object_Orientation.Yaw ) );

      Magnetometer.Sensor.read_Measurement;
      Mag := Magnetometer.Sensor.get_Sample.data;

      Logger.log_console(Logger.TRACE, "Mag (uT):" & Image(Mag(X) * 1.0e6) & ", " & Image(Mag(Y) * 1.0e6) & ", " & Image(Mag(Z) * 1.0e6) );
      G_Object_Orientation.Yaw := Heading(Mag, G_Object_Orientation);




      -- Estimate Object Position
      Barometer.Sensor.read_Measurement; -- >= 4 calls for new data
      G_state.baro_calls := Baro_Call_Type'Succ( G_state.baro_calls );
      if G_state.baro_calls = 0 then
         Height_Buffer_Pack.push_back( G_height_buffer, Barometer.Sensor.get_Altitude );
         update_Max_Height;
      end if;


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



      -- update stable measurements
      check_stable_Time;


      -- Outputs
      G_state.logger_calls := Logger_Call_Type'Succ( G_state.logger_calls );
      if G_state.logger_calls = 0 then
         log_Info;
         if G_state.fix = FIX_2D or G_state.fix = FIX_3D then
            G_pos_buffer.push_back( GPS.Sensor.get_Position );
         end if;
         G_orientation_buffer.push_back( G_Object_Orientation );
      end if;

      G_Profiler.stop;
   end update;


   procedure reset_log_calls is
   begin
      G_state.logger_calls := 0;
   end reset_log_calls;

   procedure log_Info is
   begin
      Logger.log_console(Logger.DEBUG,
                 "RPY: " & AImage( G_Object_Orientation.Roll ) &
                 ", " & AImage( G_Object_Orientation.Pitch ) &
                 ", " & AImage( G_Object_Orientation.Yaw ) &
                 "   LG,LT,AL: " & AImage( G_Object_Position.Longitude ) &
                 ", " & AImage( G_Object_Position.Latitude ) &
                 ", " & Image( get_current_Height ) & "m, Fix: " & Integer'Image( GPS_Fix_Type'Pos( G_state.fix ) ) );

      G_Profiler.log;
   end log_Info;


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
                                     -gravity_vector(Y),   -- minus
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
         avg := signal( signal'First ).Altitude / Unit_Type( 2.0 );
         for index in GPS_Buffer_Pack.Length_Type range 1 .. 2 loop
            avg := avg + signal( index ).Altitude / Unit_Type( 2.0 );
         end loop;
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
         buf : GPS_Buffer_Pack.Element_Array(1 .. GPS_Buffer_Pack.Length_Type'Last );    -- Buffer
      begin
         get_all( G_pos_buffer, buf );
         if Length(G_pos_buffer) > 1 then
            G_state.avg_gps_height := gps_average( buf );
         end if;
      end;

      if G_state.avg_gps_height > G_state.max_gps_height then
         G_state.max_gps_height := G_state.avg_gps_height;
      end if;

      -- Baro
      declare
         buf : Height_Buffer_Pack.Element_Array(1 .. Height_Buffer_Pack.Length_Type'Last);
      begin
         get_all( G_height_buffer, buf );
         if Length(G_height_buffer) > 1 then
            G_state.avg_baro_height := baro_average( buf );
         end if;
      end;

      if G_state.avg_baro_height > G_state.max_baro_height then
         G_state.max_baro_height := G_state.avg_baro_height;
      end if;

   end update_Max_Height;


   procedure check_stable_Time is
      or_values : IMU_Buffer_Pack.Element_Array(1 .. IMU_Buffer_Pack.Length_Type'Last);
      or_ref : Orientation_Type;
      pos_values : GPS_Buffer_Pack.Element_Array(1 .. GPS_Buffer_Pack.Length_Type'Last);
      pos_ref : GPS_Loacation_Type;

      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      stable : Boolean := True;
   begin
      if G_orientation_buffer.Length > 1 and G_pos_buffer.Length > 1 then
         G_state.stable_Time := G_state.stable_Time + Units.To_Time( Ada.Real_Time.Time_Span( now - G_state.last_stable_check ) );
         G_orientation_buffer.get_all(or_values);
         or_ref := or_values(1);
         for index in Integer range 1 .. G_orientation_buffer.Length loop
            if or_values(index).Roll - or_ref.Roll > 1.5 * Degree  or
            or_values(index).Pitch - or_ref.Pitch > 1.5 * Degree then
               G_state.stable_Time := 0.0 * Second;
            end if;
         end loop;

         G_pos_buffer.get_all(pos_values);
         pos_ref := pos_values(1);
         for index in Integer range 1 .. G_pos_buffer.Length loop
            if pos_values(index).Longitude - pos_ref.Longitude > 0.002 * Degree or   -- 0.002° ≈ 111 Meter
            pos_values(index).Latitude - pos_ref.Latitude > 0.002 * Degree or
            pos_values(index).Altitude - pos_ref.Altitude > 10.0 * Meter then
               G_state.stable_Time := 0.0 * Second;
            end if;
         end loop;

      else
         G_state.stable_Time := 0.0 * Second;
      end if;
      G_state.last_stable_check := now;

   end check_stable_Time;

   function get_Stable_Time return Time_Type is
   begin
      return G_state.stable_Time;
   end get_Stable_Time;

end Estimator;
