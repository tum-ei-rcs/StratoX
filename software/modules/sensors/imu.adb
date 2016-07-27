

with Ada.Real_Time; use Ada.Real_Time;

with Generic_Queue;
with Units; use Units;


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

   KM_ACC_VARIANCE : constant Unit_Type := 0.001;
   KM_GYRO_BIAS_VARIANCE : constant Unit_Type := 0.003;
   KM_MEASUREMENT_VARIANCE : constant Unit_Type := 0.03;


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
         Driver.Set_Full_Scale_Accel_Range( FS_Range => Driver.MPU6000_Accel_FS_16 );
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
      rate : Angular_Velocity_Vector;
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt : Time_Type := Units.To_Time( now - G_state.kmLastCall ); 
   begin
   
      -- 1. Predict
      ------------------
      G_state.kmRate := get_Angular_Velocity(Self) - G_state.kmBias;
      G_state.kmAngle := G_state.kmAngle + G_state.kmRate * dt;
      
      -- Calc Covariance
      G_state.kmP := ( 1 => ( 1 => G_state.kmP(2, 2) + Unit_Type(dt) * ( Unit_Type(dt) * G_state.kmP(2, 2) - G_state.kmP(1, 2) - G_state.kmP(2, 1) + KM_ACC_VARIANCE),
                              2 => G_state.kmP(1, 2) - Unit_Type(dt) * G_state.kmP(2, 2) ),
                       2 => ( 1 => G_state.kmP(2, 1) - Unit_Type(dt) * G_state.kmP(2, 2),
                              2 => G_state.kmP(2, 2) + KM_GYRO_BIAS_VARIANCE ) );
                              
      -- 2. Update
      -------------------
      G_state.kmS := G_state.kmP(1, 1) + KM_MEASUREMENT_VARIANCE;
      G_state.kmK(1) := G_state.kmP(1, 1) / G_state.kmS;
      G_state.kmK(2) := G_state.kmP(2, 1) / G_state.kmS;
      
      
      G_state.kmy := newAngle - G_state.kmAngle;
      G_state.kmAngle := G_state.kmAngle + G_state.kmK(1) * G_state.kmy;
      G_state.kmBias := G_state.kmBias + Angular_Velocity_Vector( G_state.kmK(2) * G_state.kmy );
      
      
      G_state.kmP := ( 1 => ( 1 => G_state.kmP(1, 1) - G_state.kmK(1) * G_state.kmP(1, 1),
                              2 => G_state.kmP(1, 2) - G_state.kmK(1) * G_state.kmP(1, 2) ),
                       2 => ( 1 => G_state.kmP(2, 1) - G_state.kmK(2) * G_state.kmP(1, 1),
                              2 => G_state.kmP(2, 2) - G_state.kmK(2) * G_state.kmP(1, 2) ) );
      
      
   end perform_Kalman_Filtering;
   
   
   
   function get_Linear_Acceleration(Self : IMU_Tag) return Linear_Acceleration_Vector is
      result : Linear_Acceleration_Vector;
      sensitivity : constant Float := Driver.MPU6000_G_PER_LSB_8;
      -- Arduplane: 4G
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
