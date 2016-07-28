

with Ada.Real_Time; use Ada.Real_Time;

with Generic_Queue;
with Units; use Units;
with Logger;


package body IMU is


   type State_Type is record
      filterAngle : Rotation_Vector;
      lastFuse    : Ada.Real_Time.Time;
      kmState : Orientation_Type :=  (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
      kmAngle : Orientation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
      kmBias : Angular_Velocity_Vector := (0.0 * Degree/Second, 0.0 * Degree/Second, 0.0 * Degree/Second);
      kmRate : Angular_Velocity_Vector := (0.0 * Degree/Second, 0.0 * Degree/Second, 0.0 * Degree/Second);
      kmP : Unit_Matrix2D := (1 => (0.0, 0.0), 
                              2 => (0.0, 0.0) );
      kmS         : Unit_Type := 0.0;  -- Estimate Error
      kmK : Unit_Vector2D := (0.0, 0.0);
      kmy : Rotation_Vector := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);  -- Angle difference
      kmLastCall : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   end record;
   
   G_state  : State_Type;

   KM_ACC_VARIANCE : constant Unit_Type := 0.00005;  -- old: 0.001;
   KM_GYRO_BIAS_VARIANCE : constant Unit_Type := 8.0e-6; -- old: 0.003;
   KM_MEASUREMENT_VARIANCE : constant Unit_Type := 0.003; -- old: 0.03;


   function MPU_To_PX4Frame(vector : Linear_Acceleration_Vector) return Linear_Acceleration_Vector is
      ( ( X => vector(Y), Y => -vector(X), Z => vector(Z) ) );

   function MPU_To_PX4Frame(vector : Angular_Velocity_Vector) return Angular_Velocity_Vector is
      ( ( Roll => vector(Pitch), Pitch => -vector(Roll), Yaw => vector(Yaw) ) );


   overriding
   procedure initialize (Self : in out IMU_Tag) is
   begin 
      G_state.lastFuse := Ada.Real_Time.Clock;
      G_state.kmLastCall := Ada.Real_Time.Clock;
      
      if MPU6000.Driver.Test_Connection then
         Driver.Init;
         Driver.Set_Full_Scale_Gyro_Range( FS_Range => Driver.MPU6000_Gyro_FS_2000 );
         Driver.Set_Full_Scale_Accel_Range( FS_Range => Driver.MPU6000_Accel_FS_8 );
         Self.state := READY;
      else
         Self.state := ERROR;
      end if;
   end initialize;

   overriding
   procedure read_Measurement(Self : in out IMU_Tag) is
   begin
      Driver.Get_Motion_6(Self.sample.data.Acc_X,
                          Self.sample.data.Acc_Y,
                          Self.sample.data.Acc_Z,
                          Self.sample.data.Gyro_X,
                          Self.sample.data.Gyro_Y,
                          Self.sample.data.Gyro_Z);    
   end read_Measurement;
   
   
   procedure perform_Kalman_Filtering(Self : IMU_Tag; newAngle : Orientation_Type) is
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt : Time_Type := Units.To_Time( now - G_state.kmLastCall ); 
      newRate : Angular_Velocity_Vector := get_Angular_Velocity(Self);
      BIAS_LIMIT : constant Angular_Velocity_Type := 200.0*Degree/Second;
      predAngle : Angle_Vector;
   begin
         -- Logger.log(Logger.INFO, "real time dt: " & Float'Image( Float(dt) ) );
         
         
--        if (newAngle.Roll < -90.0*Degree and G_state.kmAngle.Roll > 90.0*Degree) or (newAngle.Roll > 90.0*Degree and G_state.kmAngle.Roll < -90.0*Degree) then
--           G_state.kmAngle.Roll := newAngle.Roll;
--        end if;
--     
--        if abs( Unit_Type( newAngle.Roll )) > Unit_Type( 90.0 * Degree ) then
--           newRate(PITCH) := - newRate(PITCH);
--        end if;

 
      


   
      -- 1. Predict   F sys matrix is 
      ------------------
      G_state.kmRate := newRate - G_state.kmBias;  -- Bias bei Pitch hoch: 6.2
      -- G_state.kmAngle := G_state.kmAngle + G_state.kmRate * dt;   -- Hier muss verbessert werden!!! 80 + 15 = 85!
      
     -- G_state.kmAngle.Roll := wrap_Angle( Angle_Type( G_state.kmAngle.Roll ) + G_state.kmRate(ROLL) * dt,
       --                                   Roll_Type'First, Roll_Type'Last);
      
      predAngle(Roll) := Angle_Type( G_state.kmAngle.Roll ) + Angle_Type( G_state.kmRate(ROLL) * dt );
      predAngle(PITCH) := Angle_Type( G_state.kmAngle.Pitch ) + Angle_Type( G_state.kmRate(PITCH) * dt );
      if predAngle(PITCH) > 90.0*Degree then
         G_state.kmAngle.Pitch := 180.0*Degree - predAngle(PITCH);
      elsif predAngle(PITCH) < -90.0*Degree then
         G_state.kmAngle.Pitch := -180.0*Degree - predAngle(PITCH);
      else
         G_state.kmAngle.Pitch := predAngle(PITCH);
      end if;
      
      
     
      
      
      -- Calc Covariance, bleibt klein
      G_state.kmP := ( 1 => ( 1 => G_state.kmP(1, 1) + Unit_Type(dt) * ( Unit_Type(dt) * G_state.kmP(2, 2) - G_state.kmP(1, 2) - G_state.kmP(2, 1) + KM_ACC_VARIANCE),
                              2 => G_state.kmP(1, 2) - Unit_Type(dt) * G_state.kmP(2, 2) ),
                       2 => ( 1 => G_state.kmP(2, 1) - Unit_Type(dt) * G_state.kmP(2, 2),
                              2 => G_state.kmP(2, 2) + Unit_Type(dt) * KM_GYRO_BIAS_VARIANCE ) );
                              
      -- 2. Update
      -------------------
      G_state.kmS := G_state.kmP(1, 1) + KM_MEASUREMENT_VARIANCE;
      G_state.kmK(1) := G_state.kmP(1, 1) / G_state.kmS;   -- gains: 1 => 0.2 – 0.9 , 2 => < 0.1
      G_state.kmK(2) := G_state.kmP(2, 1) / G_state.kmS;
      
      
      -- final correction
      G_state.kmy := ( ROLL => newAngle.Roll - predAngle(ROLL),
                       PITCH => newAngle.Pitch - predAngle(PITCH),
                       YAW => newAngle.Yaw - predAngle(YAW) );  -- groß
      G_state.kmAngle := G_state.kmAngle + G_state.kmK(1) * G_state.kmy;
      G_state.kmBias := G_state.kmBias + Angular_Velocity_Vector( G_state.kmK(2) * G_state.kmy );
      
      if G_state.kmBias(PITCH) < -BIAS_LIMIT then
         G_state.kmBias(PITCH) := -BIAS_LIMIT;
      elsif G_state.kmBias(PITCH) > BIAS_LIMIT then
         G_state.kmBias(PITCH) := BIAS_LIMIT;
      end if;
      
      if G_state.kmBias(ROLL) < -BIAS_LIMIT then
         G_state.kmBias(ROLL) := -BIAS_LIMIT;
      elsif G_state.kmBias(ROLL) > BIAS_LIMIT then
         G_state.kmBias(ROLL) := BIAS_LIMIT;
      end if;    
      
      G_state.kmP := ( 1 => ( 1 => G_state.kmP(1, 1) - G_state.kmK(1) * G_state.kmP(1, 1),
                              2 => G_state.kmP(1, 2) - G_state.kmK(1) * G_state.kmP(1, 2) ),
                       2 => ( 1 => G_state.kmP(2, 1) - G_state.kmK(2) * G_state.kmP(1, 1),
                              2 => G_state.kmP(2, 2) - G_state.kmK(2) * G_state.kmP(1, 2) ) );
      
      
      G_state.kmLastCall := now;
      
   end perform_Kalman_Filtering;
   
   
   
   function get_Linear_Acceleration(Self : IMU_Tag) return Linear_Acceleration_Vector is
      result : Linear_Acceleration_Vector;
      sensitivity : constant Float := Driver.MPU6000_G_PER_LSB_8;
      -- Arduplane: +- 8G
   begin
      result := ( X => Unit_Type( Float( Self.sample.data.Acc_X ) * sensitivity ) * GRAVITY,
                  Y => Unit_Type( Float( Self.sample.data.Acc_Y ) * sensitivity ) * GRAVITY,
                  Z => Unit_Type( Float( Self.sample.data.Acc_Z ) * sensitivity ) * GRAVITY );
      result := MPU_To_PX4Frame( result );
      return result;
   end get_Linear_Acceleration;


   function get_Angular_Velocity(Self : IMU_Tag) return Angular_Velocity_Vector is
      result : Angular_Velocity_Vector;
      sensitivity : constant Angular_Velocity_Type := Unit_Type( Driver.MPU6000_DEG_PER_LSB_2000 ) * Degree / Second;
   begin
      result := ( Roll => Unit_Type( Float( Self.sample.data.Gyro_X ) ) * sensitivity,
                  Pitch => Unit_Type( Float( Self.sample.data.Gyro_Y ) ) * sensitivity,
                  Yaw => Unit_Type( Float( Self.sample.data.Gyro_Z ) ) * sensitivity );
      result := MPU_To_PX4Frame( result );
      return result;
   end get_Angular_Velocity;

   function get_Orientation(Self : IMU_Tag) return Orientation_Type is
   begin
      return G_state.kmAngle;
   end get_Orientation;



   -- Complementary Filter: angle = 0.98 *(angle+gyro*dt) + 0.02*acc
   function Fused_Orientation(Self : IMU_Tag; Orientation : Orientation_Type; Angular_Rate : Angular_Velocity_Vector) return Orientation_Type is
      result : Orientation_Type;
      fraction : constant := 0.7;
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt : Ada.Real_Time.Time_Span := now - G_state.lastFuse;
   begin
      result.Roll := fraction * ( G_state.filterAngle(Roll) + Angular_Rate(Roll) * Units.To_Time( dt ) ) +
      (1.0 - fraction) * Orientation.Roll;
      
      result.Pitch := fraction * ( G_state.filterAngle(Pitch) + Angular_Rate(Pitch) * Units.To_Time( dt ) ) +
      (1.0 - fraction) * Orientation.Pitch;
      
      G_state.lastFuse := Ada.Real_Time.Clock;
   
      return result;
   end Fused_Orientation;




   procedure check_Freefall(Self : in out IMU_Tag; isFreefall : out Boolean) is
   begin
      if abs ( Units.Vectors.Cartesian_Vector_Type( get_Linear_Acceleration(Self) ) ) < Unit_Type( 0.5 ) then
         Self.Freefall_Counter := Self.Freefall_Counter + 1;
      else 
         Self.Freefall_Counter := 0;
      end if;
      isFreefall := (Self.Freefall_Counter >= 5);
   end check_Freefall;




end IMU;
