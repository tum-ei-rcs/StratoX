
--with Generic_Signal;
--with Generic_Sensor;
with Generic_Queue;

with Ada.Real_Time; use Ada.Real_Time;

with IMU;
with GPS;
with Barometer;
with Magnetometer;

with Units.Numerics; use Units.Numerics;

with Logger;
with ULog;
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

   type State_Type is record
      fix : GPS_Fix_Type := NO_FIX;
      nsat : Unsigned_8 := 0;
      avg_gps_height : Altitude_Type := 0.0 * Meter;
      max_gps_height : Altitude_Type := 0.0 * Meter;
      avg_baro_height : Altitude_Type := 0.0 * Meter;
      max_baro_height : Altitude_Type := 0.0 * Meter;
      height_deviation : Linear_Velocity_Type := 0.0 * Meter/Second;
      baro_calls : Baro_Call_Type := 0;
      logger_calls : Logger_Call_Type := 0;
      logger_console_calls : Logger_Call_Type := 0;
      stable_Time     : Time_Type := 0.0 * Second;
      last_stable_check : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
      home_pos : GPS_Loacation_Type;
      home_baro_alt : Altitude_Type := 0.0 * Meter;
   end record;

   type Sensor_Record is record
      GPS1  : GPS.GPS_Tag;
      Baro1 : Barometer.Barometer_Tag;
      IMU1  : IMU.IMU_Tag;
      Mag1  : Magnetometer.Magnetometer_Tag;
   end record;
   pragma Unreferenced (Sensor_Record);

   type IMU_Data_Type is record
      Acc  : Linear_Acceleration_Vector;
      Gyro : Angular_Velocity_Vector;
   end record;


   G_state  : State_Type;
   G_imu    : IMU_Data_Type;
   -- G_Sensor : Sensor_Record;

   G_height_buffer : Height_Buffer_Pack.Buffer_Tag;
   G_pos_buffer : GPS_Buffer_Pack.Buffer_Tag;

   G_orientation_buffer : IMU_Buffer_Pack.Buffer_Tag;

   G_Profiler : Profiler.Profile_Tag;



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
      Barometer.Sensor.read_Measurement;

      GPS.Sensor.initialize;

      -- Profiler
      G_Profiler.init("Estimator");

      Logger.log_console(Logger.INFO, "Estimator initialized");
   end initialize;

   -- fetch fresh measurement data
   procedure update is
      Acc_Orientation : Orientation_Type;
      CF_Orientation : Orientation_Type;
      Mag : Magnetic_Flux_Density_Vector;
      GFixS : String := "NO";
      pragma Unreferenced (GFixS);

   begin
      G_Profiler.start;

      -- Estimate Object Orientation
      IMU.Sensor.read_Measurement;
      G_imu.Acc := IMU.Sensor.get_Linear_Acceleration;
      G_imu.Gyro := IMU.Sensor.get_Angular_Velocity;

      -- Logger.log_console(Logger.DEBUG,"Acc: " & Image(G_imu.Acc(X)) & ", "
      --      & Image(G_imu.Acc(Y)) & ", " & Image(G_imu.Acc(Z)) );
      -- Logger.log_console(Logger.DEBUG,"Gyro: " & AImage(G_imu.Gyro(Roll)*Second)
      --      & ", " & AImage(G_imu.Gyro(Pitch)*Second) & ", " & AImage(G_imu.Gyro(YAW)*Second) );
      -- Logger.log_console(Logger.DEBUG,"Gyro: " & RImage(G_imu.Gyro(Roll)*Second)
      --      & ", " & RImage(G_imu.Gyro(Pitch)*Second) & ", " & RImage(G_imu.Gyro(YAW)*Second) );


      Acc_Orientation := Orientation( G_imu.Acc );
      -- CF_Orientation := IMU.Fused_Orientation( IMU.Sensor, Acc_Orientation, Gyro);
      IMU.perform_Kalman_Filtering( IMU.Sensor, Acc_Orientation );
      G_Object_Orientation := IMU.Sensor.get_Orientation;


      -- Logger.log_console(Logger.INFO, "RPY: " & AImage( Acc_Orientation.Roll ) & ", "
      --     & AImage( Acc_Orientation.Pitch ) & ", " & AImage( Acc_Orientation.Yaw ) );
      -- Logger.log_console(Logger.INFO, "CF : " & AImage( CF_Orientation.Roll ) & ", "
      --     & AImage( CF_Orientation.Pitch ) & ", " & AImage( CF_Orientation.Yaw ) );
      -- Logger.log_console(Logger.INFO, "KM : " & AImage( G_Object_Orientation.Roll ) & ", "
      --     & AImage( G_Object_Orientation.Pitch ) & ", " & AImage( G_Object_Orientation.Yaw ) );

      Magnetometer.Sensor.read_Measurement;
      Mag := Magnetometer.Sensor.get_Sample.data;

      -- Logger.log_console(Logger.DEBUG, "Mag (uT):" & Image(Mag(X) * 1.0e6) & ", " & Image(Mag(Y) * 1.0e6) & ", " & Image(Mag(Z) * 1.0e6) );
      G_Object_Orientation.Yaw := Heading(Mag, G_Object_Orientation);




      -- Estimate Object Position
      Barometer.Sensor.read_Measurement; -- >= 4 calls for new data
      G_state.baro_calls := Baro_Call_Type'Succ( G_state.baro_calls );
      if G_state.baro_calls = 0 then
         declare
            previous_height : Altitude_Type := 0.0*Meter;
         begin
            if Height_Buffer_Pack.Length( G_height_buffer ) > 0 then
               Height_Buffer_Pack.get_front( G_height_buffer, previous_height );
               -- G_state.height_deviation := (Barometer.Sensor.get_Altitude - previous_height ) / dt;
            end if;
         end;
         Height_Buffer_Pack.push_back( G_height_buffer, Barometer.Sensor.get_Altitude );
         update_Max_Height;
      end if;


      GPS.Sensor.read_Measurement;
      G_state.fix := GPS.Sensor.get_GPS_Fix;
      G_state.nsat := GPS.Sensor.get_Num_Sats;
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
      imu_msg : ULog.Message (ULog.IMU);
      gps_msg : ULog.Message (ULog.GPS);
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin

      G_state.logger_console_calls := Logger_Call_Type'Succ( G_state.logger_console_calls );
      if G_state.logger_console_calls = 0 then
         Logger.log_console(Logger.DEBUG,
                            "RPY: " & AImage( G_Object_Orientation.Roll ) &
                            ", " & AImage( G_Object_Orientation.Pitch ) &
                            ", " & AImage( G_Object_Orientation.Yaw ) &
                            "   LG,LT,AL: " & AImage( G_Object_Position.Longitude ) &
                            ", " & AImage( G_Object_Position.Latitude ) &
                            ", " & Image( get_current_Height ) & "m, Fix: " & Integer'Image( GPS_Fix_Type'Pos( G_state.fix ) ) );

         G_Profiler.log;
      end if;

      -- log to SD
      imu_msg := ( Typ => ULog.IMU,
                          t => now,
                          accX  => Float( G_imu.Acc(X) ),
                          accY  => Float( G_imu.Acc(Y) ),
                          accZ  => Float( G_imu.Acc(Z) ),
                          gyroX => Float( G_imu.Gyro(X) ),
                          gyroY => Float( G_imu.Gyro(Y) ),
                          gyroZ => Float( G_imu.Gyro(Z) ),
                          roll  => Float( G_Object_Orientation.Roll ),
                          pitch => Float( G_Object_Orientation.Pitch ),
                          yaw   => Float( G_Object_Orientation.Yaw )
      );

      gps_msg := ( Typ => ULog.GPS,
                   t => now,
                   gps_week => 0,
                   gps_msec => 0,
                   fix      => Unsigned_8 (GPS_Fix_Type'Pos( G_state.fix )),
                   nsat     => G_state.nsat,
                   lat      => Float( G_Object_Position.Latitude / Degree ),
                   lon      => Float( G_Object_Position.Longitude / Degree ),
                   alt      => Float( G_Object_Position.Altitude )
      );

      Logger.log_sd( Logger.INFO, imu_msg );
      Logger.log_sd( Logger.INFO, gps_msg );


   end log_Info;


   procedure lock_Home(position : GPS_Loacation_Type; baro_height : Altitude_Type) is
   begin
      G_state.home_pos := position;
      G_state.home_baro_alt := baro_height;

      G_state.avg_baro_height := baro_height;
      G_state.avg_gps_height := position.Altitude;
   end lock_Home;



   function get_Orientation return Orientation_Type is
   begin
      return G_Object_Orientation;
   end get_Orientation;

   function get_Position return GPS_Loacation_Type is
   begin
      -- G_Object_Position.Altitude := 0.0 * Meter - G_state.avg_baro_height;
      return G_Object_Position;
   end get_Position;

   function get_GPS_Fix return GPS_Fix_Type is
   begin
      return G_state.fix;
   end get_GPS_Fix;

   function get_Num_Sat return Unsigned_8 is
   begin
      return G_state.nsat;
   end get_Num_Sat;

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


   function get_relative_Height return Altitude_Type is
      result : Altitude_Type;
   begin
      if G_state.fix = FIX_3D then
         result := G_state.avg_gps_height - G_state.home_pos.Altitude;
      else
         result := G_state.avg_baro_height - G_state.home_baro_alt;
      end if;
      return result;
   end get_relative_Height;


   function get_Baro_Height return Altitude_Type is
   begin
      return G_state.avg_baro_height;
   end get_Baro_Height;


   function Orientation(acc_vector : Linear_Acceleration_Vector) return Orientation_Type is
      angles : Orientation_Type;
      g_length : Float := 0.0;
      gravity_vector : Linear_Acceleration_Vector := acc_vector;
   begin
      -- normalize vector
      if abs(gravity_vector) < 0.7*GRAVITY or 1.3*GRAVITY < abs(gravity_vector) then
         gravity_vector(Z) := gravity_vector(Z) - (  sgn( gravity_vector(Z) ) * (abs(gravity_vector) - GRAVITY) );
      end if;

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
         avg := Altitude_Type( 0.0 );
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
         if Length(G_height_buffer) = Height_Buffer_Pack.Length_Type'Last then
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

      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      stable : Boolean := True;
   begin
      if G_orientation_buffer.Length > 1 and G_pos_buffer.Length > 1 then
         G_state.stable_Time := G_state.stable_Time + Units.To_Time( now - G_state.last_stable_check );
         G_orientation_buffer.get_all(or_values);
         or_ref := or_values(1);
         for index in Integer range 1 .. G_orientation_buffer.Length loop
            if or_values(index).Roll - or_ref.Roll > 1.5 * Degree  or
              or_values(index).Pitch - or_ref.Pitch > 1.5 * Degree
            then
               G_state.stable_Time := 0.0 * Second;
            end if;
         end loop;

         G_pos_buffer.get_all(pos_values);
         pos_ref := pos_values(1);
         for index in Integer range 1 .. G_pos_buffer.Length loop
            if pos_values(index).Longitude - pos_ref.Longitude > 0.002 * Degree or   -- 0.002° ≈ 111 Meter
            pos_values(index).Latitude - pos_ref.Latitude > 0.002 * Degree or
              pos_values(index).Altitude - pos_ref.Altitude > 10.0 * Meter
            then
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
