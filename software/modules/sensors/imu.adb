
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with MPU6000.Driver; use MPU6000;

package body IMU with
SPARK_Mode,
  Refined_State => (State => (G_state))
is

   ----------------
   --  TYPES
   ----------------
   
   type Kalman_Type is record
      Angle : Angle_Type := 0.0 * Degree;
      Bias : Angular_Velocity_Type := 0.0 * Degree/Second;
      Rate : Angular_Velocity_Type := 0.0 * Degree/Second;
      P    : Unit_Matrix2D := (1 => (0.0, 0.0), 2 => (0.0, 0.0) );
      K    : Unit_Vector2D := (0.0, 0.0); -- Kalman Gain
      S    : Unit_Type := 0.0;  -- Estimate Error
      y    : Angle_Type := 0.0 * Degree;  -- Angle difference 
   end record;


   type State_Type is record
      filterAngle : Rotation_Vector;
      lastFuse    : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
      kmState : Orientation_Type :=  (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
      kmLastCall : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
      kmRoll  : Kalman_Type;
      kmPitch : Kalman_Type;
   end record;
   
   G_state  : State_Type;

   ------------------
   --  CONSTANTS
   ------------------
   
   KM_ACC_VARIANCE : constant Unit_Type := 0.001;  -- tut: 0.001 px4: 0.00005;
   KM_GYRO_BIAS_VARIANCE : constant Unit_Type := 0.005; -- tut: 0.003, px4: 8.0e-6;
   KM_MEASUREMENT_VARIANCE : constant Unit_Type := 0.008; -- tut: 0.03, px4: 0.003?;


   function MPU_To_PX4Frame(vector : Linear_Acceleration_Vector) return Linear_Acceleration_Vector is
     ( ( X => vector(Y), Y => -vector(X), Z => vector(Z) ) );

   function MPU_To_PX4Frame(vector : Angular_Velocity_Vector) return Angular_Velocity_Vector is
     ( ( X => vector(Y), Y => -vector(X), Z => vector(Z) ) );


   --overriding
   procedure initialize (Self : in out IMU_Tag) is
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      success : Boolean;
   begin 
      G_state.lastFuse := now;
      G_state.kmLastCall := now;
      
      MPU6000.Driver.Test_Connection (success);
      if success then
         Driver.Init;
         Driver.Set_Full_Scale_Gyro_Range( FS_Range => Driver.MPU6000_Gyro_FS_2000 );
         Driver.Set_Full_Scale_Accel_Range( FS_Range => Driver.MPU6000_Accel_FS_8 );
         Self.state := READY;
      else
         Self.state := ERROR;
      end if;
   end initialize;

   --overriding
   procedure read_Measurement(Self : in out IMU_Tag) is
   begin
      Driver.Get_Motion_6(Self.sample.data.Acc_X,
                          Self.sample.data.Acc_Y,
                          Self.sample.data.Acc_Z,
                          Self.sample.data.Gyro_X,
                          Self.sample.data.Gyro_Y,
                          Self.sample.data.Gyro_Z);    
   end read_Measurement;
   
   
   procedure perform_Kalman_Filtering(Self : IMU_Tag; newAngle : Orientation_Type)
   is
      time_of_call : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt : constant Time_Type := Units.To_Time( time_of_call - G_state.kmLastCall ); 
      newRate : Angular_Velocity_Vector := get_Angular_Velocity(Self);
      BIAS_LIMIT : constant Angular_Velocity_Type := 500.0*Degree/Second;
      predAngle : Angle_Vector;


   begin
      -- Logger.log(Logger.INFO, "real time dt: " & Float'Image( Float(dt) ) );
         
      -- Vermutung: Bei Roll arbeiten Acc und Gyro gegeneinander.

      -------------------
      --  Preprocessing
      -------------------

      --  compensate gyros
      declare
         --  SPARK needs explicit conversion between array with different elements:
         cv : Cartesian_Vector_Type := (X => Unit_Type (newRate(X)), Y => Unit_Type (newRate(Y)), Z => Unit_Type (newRate(Z)));
      begin
         rotate (cv, X, G_state.kmRoll.Angle);
         newRate := (X => Angular_Velocity_Type (cv(X)), Y => Angular_Velocity_Type (cv(Y)), Z => Angular_Velocity_Type (cv(Z)));
      end;

      -- if roll > 90° then gyro pitch rate is inverse.
      -- not needed if gyro is compensated
      --        if abs( Unit_Type( G_state.kmRoll.Angle  )) > Unit_Type( 90.0 * Degree ) then
      --           newRate(Y) := - newRate(Y);
      --        end if;



      -- looping: if |pitch| exceeds 90°, the roll flips by 180°? => no, flight dynamic prevents this
      

      -- rollover: switch from -180 to 180°
      if (newAngle.Roll < -90.0*Degree and G_state.kmRoll.Angle > 90.0*Degree) or 
        (newAngle.Roll > 90.0*Degree and G_state.kmRoll.Angle < -90.0*Degree) then
         G_state.kmRoll.Angle := newAngle.Roll;
      end if;
         

      ------------------
      --  ROLL KALMAN
      ------------------
   
      --  1. Predict
      G_state.kmRoll.Rate := newRate(X) - G_state.kmRoll.Bias;  -- Bias bei Pitch hoch: 6.2    
      predAngle(X) := wrap_Angle(  G_state.kmRoll.Angle  + Angle_Type( G_state.kmRoll.Rate * dt ),
                                   Roll_Type'First, Roll_Type'Last);
                                    
      G_state.kmRoll.Angle := predAngle(X);
    
      -- Calc Covariance, stays small
      G_state.kmRoll.P := ( 1 => ( 1 => G_state.kmRoll.P(1, 1) + Unit_Type(dt) * 
                                   ( Unit_Type(dt) * G_state.kmRoll.P(2, 2) 
                                      - G_state.kmRoll.P(1, 2) 
                                      - G_state.kmRoll.P(2, 1) 
                                      + KM_ACC_VARIANCE),
                                   2 => G_state.kmRoll.P(1, 2) - Unit_Type(dt) * G_state.kmRoll.P(2, 2) ),
                            2 => ( 1 => G_state.kmRoll.P(2, 1) - Unit_Type(dt) * G_state.kmRoll.P(2, 2),
                                   2 => G_state.kmRoll.P(2, 2) + Unit_Type(dt) * KM_GYRO_BIAS_VARIANCE ) );
                              
      --  2. Update
      G_state.kmRoll.S    := G_state.kmRoll.P(1, 1) + KM_MEASUREMENT_VARIANCE;
      G_state.kmRoll.K(1) := G_state.kmRoll.P(1, 1) / G_state.kmRoll.S;   -- gains: 1 => 0.2 – 0.9 , 2 => < 0.1
      G_state.kmRoll.K(2) := G_state.kmRoll.P(2, 1) / G_state.kmRoll.S;
      
      --  final correction
      G_state.kmRoll.y := newAngle.Roll - G_state.kmRoll.Angle;
      G_state.kmRoll.Angle := wrap_Angle( G_state.kmRoll.Angle + G_state.kmRoll.K(1) * G_state.kmRoll.y,
                                          Roll_Type'First, Roll_Type'Last);
      G_state.kmRoll.Bias  := G_state.kmRoll.Bias + Angular_Velocity_Type( G_state.kmRoll.K(2) * G_state.kmRoll.y );
      
      if G_state.kmRoll.Bias < -BIAS_LIMIT then
         G_state.kmRoll.Bias := -BIAS_LIMIT;
      elsif G_state.kmRoll.Bias > BIAS_LIMIT then
         G_state.kmRoll.Bias := BIAS_LIMIT;
      end if;
      
      G_state.kmRoll.P := ( 1 => ( 1 => G_state.kmRoll.P(1, 1) - G_state.kmRoll.K(1) * G_state.kmRoll.P(1, 1),
                                   2 => G_state.kmRoll.P(1, 2) - G_state.kmRoll.K(1) * G_state.kmRoll.P(1, 2) ),
                            2 => ( 1 => G_state.kmRoll.P(2, 1) - G_state.kmRoll.K(2) * G_state.kmRoll.P(1, 1),
                                   2 => G_state.kmRoll.P(2, 2) - G_state.kmRoll.K(2) * G_state.kmRoll.P(1, 2) ) );
      

      -----------
      -- PITCH
      -----------
    
      --  1. Predict
      G_state.kmPitch.Rate := newRate(Y) - G_state.kmPitch.Bias;   
      
      predAngle(Y) :=  G_state.kmPitch.Angle  + Angle_Type( G_state.kmPitch.Rate * dt );
      
      --  if pitch prediction exceeds |90°|, the remainder has to be inverted: 80° + 15° = 85°!
      if predAngle(Y) > 90.0*Degree then
         G_state.kmPitch.Angle := 180.0*Degree - predAngle(Y);
      elsif predAngle(Y) < -90.0*Degree then
         G_state.kmPitch.Angle := -180.0*Degree - predAngle(Y);
      else
         G_state.kmPitch.Angle := predAngle(Y);
      end if;
            
      --  Calc Covariance, bleibt klein
      G_state.kmPitch.P := ( 1 => ( 1 => G_state.kmPitch.P(1, 1) + Unit_Type(dt) * 
                                    ( Unit_Type(dt) * G_state.kmPitch.P(2, 2) 
                                       - G_state.kmPitch.P(1, 2) 
                                       - G_state.kmPitch.P(2, 1) 
                                       + KM_ACC_VARIANCE),
                                    2 => G_state.kmPitch.P(1, 2) - Unit_Type(dt) * G_state.kmPitch.P(2, 2) ),
                             2 => ( 1 => G_state.kmPitch.P(2, 1) - Unit_Type(dt) * G_state.kmPitch.P(2, 2),
                                    2 => G_state.kmPitch.P(2, 2) + Unit_Type(dt) * KM_GYRO_BIAS_VARIANCE ) );
                              
      --  2. Update
      G_state.kmPitch.S    := G_state.kmPitch.P(1, 1) + KM_MEASUREMENT_VARIANCE;
      G_state.kmPitch.K(1) := G_state.kmPitch.P(1, 1) / G_state.kmPitch.S;   -- gains: 1 => 0.2 – 0.9 , 2 => < 0.1
      G_state.kmPitch.K(2) := G_state.kmPitch.P(2, 1) / G_state.kmPitch.S;
      
      --  final correction
      G_state.kmPitch.y := newAngle.Pitch - G_state.kmPitch.Angle;
      G_state.kmPitch.Angle := wrap_Angle( G_state.kmPitch.Angle + G_state.kmPitch.K(1) * G_state.kmPitch.y,
                                           Pitch_Type'First, Pitch_Type'Last);      
      G_state.kmPitch.Bias  := G_state.kmPitch.Bias + Angular_Velocity_Type( G_state.kmPitch.K(2) * G_state.kmPitch.y );
      
      if G_state.kmPitch.Bias < -BIAS_LIMIT then
         G_state.kmPitch.Bias := -BIAS_LIMIT;
      elsif G_state.kmPitch.Bias > BIAS_LIMIT then
         G_state.kmPitch.Bias := BIAS_LIMIT;
      end if;
      
      G_state.kmPitch.P := ( 1 => ( 1 => G_state.kmPitch.P(1, 1) - G_state.kmPitch.K(1) * G_state.kmPitch.P(1, 1),
                                    2 => G_state.kmPitch.P(1, 2) - G_state.kmPitch.K(1) * G_state.kmPitch.P(1, 2) ),
                             2 => ( 1 => G_state.kmPitch.P(2, 1) - G_state.kmPitch.K(2) * G_state.kmPitch.P(1, 1),
                                    2 => G_state.kmPitch.P(2, 2) - G_state.kmPitch.K(2) * G_state.kmPitch.P(1, 2) ) );      
      
      G_state.kmLastCall := time_of_call;      
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
      result := ( X => Unit_Type( Float( Self.sample.data.Gyro_X ) ) * sensitivity,
                  Y => Unit_Type( Float( Self.sample.data.Gyro_Y ) ) * sensitivity,
                  Z => Unit_Type( Float( Self.sample.data.Gyro_Z ) ) * sensitivity );
      result := MPU_To_PX4Frame( result );
      return result;
   end get_Angular_Velocity;

   function get_Orientation(Self : IMU_Tag) return Orientation_Type is
      pragma Unreferenced (Self);
      r : constant Roll_Type := wrap_Angle (angle => G_state.kmRoll.Angle, min => Roll_Type'First, max => Roll_Type'Last);
      p : constant Pitch_Type := wrap_Angle (angle => G_state.kmPitch.Angle, min => Pitch_Type'First, max => Pitch_Type'Last);
   begin
      return (Roll => r, Pitch => p, Yaw => 0.0 * Degree);
   end get_Orientation;



   -- Complementary Filter: angle = 0.98 *(angle+gyro*dt) + 0.02*acc
   procedure Fused_Orientation(Self : IMU_Tag; Orientation : Orientation_Type; 
                               Angular_Rate : Angular_Velocity_Vector;
                               result : out Orientation_Type) is
      pragma Unreferenced (Self);
      fraction : constant := 0.7;
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt  : constant Ada.Real_Time.Time_Span := now - G_state.lastFuse;
      
      function Sat_Add_Angle is new Saturated_Addition (Angle_Type);      
   begin
      declare
         tmp : constant Angle_Type := Sat_Add_Angle (G_state.filterAngle(X), Angular_Rate(X) * Units.To_Time (dt));
      begin
         result.Roll := wrap_Angle (angle => Sat_Add_Angle (fraction * tmp, (1.0 - fraction) * Orientation.Roll), 
                                    min => Roll_Type'First, 
                                    max => Roll_Type'Last);
      end;
      
      declare
         tmp : constant Angle_Type := Sat_Add_Angle (G_state.filterAngle(Y), Angular_Rate(Y) * Units.To_Time(dt));
      begin
         result.Pitch := wrap_Angle (angle => Sat_Add_Angle (fraction * tmp, (1.0 - fraction) * Orientation.Pitch),
                                     min => Pitch_Type'First,
                                     max => Pitch_Type'Last);
      end;
      
      result.Yaw := Orientation.Yaw;
      
      G_state.lastFuse := Ada.Real_Time.Clock;      
   end Fused_Orientation;




   procedure check_Freefall(Self : in out IMU_Tag; isFreefall : out Boolean) is
      function Sat_Add_Flt is new Saturated_Addition (Float);
      
      function "abs" (value : Linear_Acceleration_Vector) return Linear_Acceleration_Type is
         lensq : Float;                                       
      begin
         lensq := Sat_Add_Flt (Float (value(X))**2, Float (value(Y))**2);
         lensq := Sat_Add_Flt (lensq, Float (value(Z))**2);
         return Linear_Acceleration_Type (Sqrt (lensq));   
      end "abs";
      
   begin
      if abs (get_Linear_Acceleration (Self)) < 0.5 * Meter / (Second**2) then
         if Self.Freefall_Counter < Natural'Last then
            Self.Freefall_Counter := Self.Freefall_Counter + 1;
         end if;
      else 
         Self.Freefall_Counter := 0;
      end if;
      isFreefall := (Self.Freefall_Counter >= 5);
   end check_Freefall;




end IMU;
