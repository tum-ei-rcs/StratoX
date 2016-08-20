
with Ada.Real_Time; use Ada.Real_Time;

with Ada.Numerics.Generic_Real_Arrays;
with Units.Vectors; use Units.Vectors.Unit_Arrays_Pack;

with Logger;
with Profiler;

package body Kalman with SPARK_Mode,
  Refined_State => (State => (G, KM_Profiler))
is

   k : constant := State_Vector_Index_Type'Last;  -- states
   l : constant := Input_Vector_Index_Type'Last;   -- inputs 
   m : constant := Observation_Vector_Index_Type'Last;  -- observations  
   
   -- all the global data together
   type Global_Type is record
      t_last : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
   
      x : State_Vector;        -- k states
      u : Input_Vector;        -- l inputs
      z : Observation_Vector;  -- m observations 

      A : State_Transition_Matrix;   -- k×k
      B : Input_Transition_Matrix;   -- k×l
      H : Observation_Transition_Matrix;  -- m×k

      P : State_Covariance_Matrix;   -- k×k

      Q : State_Noise_Covariance_Matrix; -- k×k
      R : Observation_Noise_Covariance_Matrix; -- m×m
   end record;


   --------------------
   --  INTERNAL STATES
   --------------------

   G : Global_Type;
   KM_Profiler : Profiler.Profile_Tag;


   ANGLE_PROCESS_VARIANCE : constant := 1.0e-4;  -- 1.0e-4  trust in orientation prediction (gyro integral)
   RATE_PROCESS_VARIANCE  : constant := 3.0e-2;  -- 1.0e-2 dont trust in rate prediction
   BIAS_PROCESS_VARIANCE  : constant := 1.0e-12;  -- trust in prev bias (really slow bias drift?)
      
   ANGLE_MEASUREMENT_VARIANCE : constant := 6.0e-3;  -- 3.0e-2 dont trust in angle measurement (acc arctan)
   RATE_MEASUREMENT_VARIANCE : constant := 1.0e-4;   -- 1.0e-3 trust rate measurement


   -----------------
   --  reset
   -----------------
   procedure reset( init_states : State_Vector := DEFAULT_INIT_STATES ) is 
      now : constant Time := Clock;      
   begin
      G.t_last := now;
      
      -- initial states:
      G.x := init_states;
      
      
      -- init matrices with zero
      G.A := (others => (others => 0.0));
      G.H := (others => (others => 0.0));
      
      -- Set H Measurement Matrix
      G.H( map(Z_LON) , map(X_LON) )  := 1.0;
      G.H( map(Z_LAT), map(X_LAT) ) := 1.0;
      G.H( map(Z_ALT)  , map(X_ALT) )   := 1.0;
      G.H( map(Z_BARO_ALT), map(X_ALT) ) := 1.0;
      G.H( map(Z_ROLL) , map(X_ROLL) )  := 1.0;
      G.H( map(Z_PITCH), map(X_PITCH) ) := 1.0;
      G.H( map(Z_YAW)  , map(X_YAW) )   := 1.0;
      G.H( map(Z_ROLL_RATE) , map(X_ROLL_RATE) )  := 1.0;
      G.H( map(Z_PITCH_RATE), map(X_PITCH_RATE) ) := 1.0;
      G.H( map(Z_YAW_RATE)  , map(X_YAW_RATE) )   := 1.0;
      
--        G.H( map(Z_ROLL) , map(X_ROLL_BIAS) )  := -1.0;  -- gyro measurements INCLUDES bias
--        G.H( map(Z_PITCH), map(X_PITCH_BIAS) ) := -1.0;
--        G.H( map(Z_YAW)  , map(X_YAW_BIAS) )   := -1.0;
        

      -- Set A, Dynamic Matrix
      declare
         A : State_Transition_Matrix;
         --  avoid forbidden aliasing by copying the result into G after the call (SPARK RM 6.4.2)
      begin
         calculate_A( A, 0.0 * Second);
         G.A := A;
      end;

      -- Set P, Covariance Matrix to high values => uncertain about init values
      G.P := Eye( k ) * 10.0;
      G.P( map(X_ROLL), map(X_ROLL) ) := ANGLE_PROCESS_VARIANCE;
      G.P( map(X_PITCH), map(X_PITCH) ) := ANGLE_PROCESS_VARIANCE;
      G.P( map(X_YAW), map(X_YAW) ) := ANGLE_PROCESS_VARIANCE;      
      
      G.P( map(X_ROLL_BIAS), map(X_ROLL_BIAS) ) := BIAS_PROCESS_VARIANCE;   -- we are sure about the bias 
      G.P( map(X_PITCH_BIAS), map(X_PITCH_BIAS) ) := BIAS_PROCESS_VARIANCE;   -- we are sure about the bias 
                                                               
      
      -- Process Noise
      G.Q := Eye( k ) * 1.0e-1;
      G.Q( map(X_ROLL), map(X_ROLL) ) := ANGLE_PROCESS_VARIANCE;
      G.Q( map(X_PITCH), map(X_PITCH) ) := ANGLE_PROCESS_VARIANCE * 100.0;
      G.Q( map(X_YAW), map(X_YAW) ) := ANGLE_PROCESS_VARIANCE;

      G.Q( map(X_ROLL_RATE), map(X_ROLL_RATE) ) := RATE_PROCESS_VARIANCE;
      G.Q( map(X_PITCH_RATE), map(X_PITCH_RATE) ) := RATE_PROCESS_VARIANCE;    
      G.Q( map(X_YAW_RATE), map(X_YAW_RATE) ) := RATE_PROCESS_VARIANCE;
      
      G.Q( map(X_ROLL_BIAS), map(X_ROLL_BIAS) ) := BIAS_PROCESS_VARIANCE;
      G.Q( map(X_PITCH_BIAS), map(X_PITCH_BIAS) ) := BIAS_PROCESS_VARIANCE;
   
      -- Set P to Q
      G.P := G.Q;
   
   
      
      -- Measurement Noise
      G.R := Eye( m ) * 1.0e-3; -- default
      G.R( map(Z_ROLL), map(Z_ROLL) ) := ANGLE_MEASUREMENT_VARIANCE;
      G.R( map(Z_PITCH), map(Z_PITCH) ) := ANGLE_MEASUREMENT_VARIANCE / 100.0;
      G.R( map(Z_YAW), map(Z_YAW) ) := ANGLE_MEASUREMENT_VARIANCE;
      
      G.R( map(Z_ROLL_RATE), map(Z_ROLL_RATE) ) := RATE_MEASUREMENT_VARIANCE;
      G.R( map(Z_PITCH_RATE), map(Z_PITCH_RATE) ) := RATE_MEASUREMENT_VARIANCE;
      G.R( map(Z_YAW_RATE), map(Z_YAW_RATE) ) := RATE_MEASUREMENT_VARIANCE;
            
   end reset;

   -------------------------
   --  perform_Filter_Step
   -------------------------
   
   procedure perform_Filter_Step( u : in Input_Vector; z : in Observation_Vector ) is
      now : constant Time := Clock;
      dt  : constant Time_Type := To_Time(now - G.t_last);
   begin
      KM_Profiler.start;
      predict(u, dt);
      update(z, dt);
      KM_Profiler.stop;
      --KM_Profiler.log;
      
      G.t_last := now;          
   end perform_Filter_Step;

   -------------------------
   --  predict
   -------------------------
   
   procedure predict(u : Input_Vector; dt : Time_Type) is 
   begin
      declare
         x : State_Vector := G.x;
         --  avoid forbidden aliasing by copying the result into G after the call (SPARK RM 6.4.2)
      begin
         predict_state( x, u, dt );
         G.x := x;
      end;
      declare
         P : State_Covariance_Matrix := G.P;
         --  avoid forbidden aliasing by copying the result into G after the call (SPARK RM 6.4.2)
      begin         
         predict_cov( P, G.Q );
         G.P := P;
      end;
   end predict;

   -------------------------
   --  update
   -------------------------
   
   procedure update(z : Observation_Vector; dt : Time_Type) is
      K : Kalman_Gain_Matrix;
      residual : Innovation_Vector;
   begin
      estimate_observation_noise_cov( G.R, G.x, z);
      declare
         x : constant State_Vector := G.x;
         --  avoid forbidden aliasing by copying the result into G after the call (SPARK RM 6.4.2)
      begin
         calculate_gain( x, z, dt, K, residual ); 
      end;
      uptate_state( G.x, K, residual, dt );
      declare
         P : State_Covariance_Matrix := G.P;
         --  avoid forbidden aliasing by copying the result into G after the call (SPARK RM 6.4.2)
      begin
         update_cov( P, K );
         G.P := P;
      end;
   end update;

   -------------------------
   --  get_States
   -------------------------
   
   function get_States return State_Vector is
   begin
      return G.x;
   end get_States;
   
   -------------------------
   --  predict_state
   -------------------------   
   
   procedure predict_state( state : in out State_Vector; input : Input_Vector; dt : Time_Type ) with SPARK_Mode => Off -- see below
   is
      new_state : State_Vector := state;
      
      ELEVON_TO_GYRO : constant Frequency_Type := 0.5 * Hertz;
      PITCH_TO_AIRSPEED : constant := 0.5 * Meter / ( Degree * Second );
      compensated_rates : Angular_Velocity_Vector := state.rates;
      
   begin
      -- gyro compensation
      rotate( Cartesian_Vector_Type( compensated_rates ), X , state.orientation.Roll ); -- SPARK error: conversion  between array types that have dofferent element types is not yet supported
   
      -- state prediction
      new_state.orientation := state.orientation + (compensated_rates - state.bias) * dt;
      new_state.rates(X) := state.rates(X) + (input.Aileron - G.u.Aileron)/Second * ELEVON_TO_GYRO * dt;
      new_state.rates(Y) := state.rates(Y) + (input.Elevator - G.u.Elevator)/Second * ELEVON_TO_GYRO * dt;
      new_state.bias := state.bias;
      new_state.pos := state.pos; -- + state.ground_speed * dt;
      new_state.air_speed(X) := state.air_speed(X) - state.orientation.Pitch * PITCH_TO_AIRSPEED;
      
      state := new_state;
      G.u := input;
      
      -- estimate Q

   end predict_state;   

   -------------------------
   --  predict_cov
   -------------------------    

   procedure predict_cov( P : in out State_Covariance_Matrix; Q : State_Noise_Covariance_Matrix ) is
   begin
      P := G.A * P * Transpose(G.A) + Q;
   end predict_cov;


   procedure estimate_observation_noise_cov( R : in out Observation_Noise_Covariance_Matrix; 
                                             states : State_Vector;
                                             samples : Observation_Vector
                                             ) is
      RATE_REF : constant Angular_Velocity_Type := 200.0*Degree/Second;
   begin
      R( map(Z_ROLL), map(Z_ROLL) ) := ANGLE_MEASUREMENT_VARIANCE +
         30.0* ANGLE_MEASUREMENT_VARIANCE * abs(samples.acc_length/GRAVITY - Unit_Type(1.0)) +
         10.0* ANGLE_MEASUREMENT_VARIANCE * abs(states.orientation.Pitch/Pitch_Type'Last) +
         50.0* ANGLE_MEASUREMENT_VARIANCE * abs(states.rates(X)/RATE_REF);
      
      R( map(Z_PITCH), map(Z_PITCH) ) := ANGLE_MEASUREMENT_VARIANCE + 
         10.0* ANGLE_MEASUREMENT_VARIANCE * abs(samples.acc_length/GRAVITY - Unit_Type(1.0)) +
         30.0* ANGLE_MEASUREMENT_VARIANCE * abs(states.rates(Y)/RATE_REF);
   end estimate_observation_noise_cov;

   -------------------------
   --  Minus
   -------------------------
   
   function "-"(Left, Right : Observation_Vector) return Innovation_Vector is
   begin
      return ( Left.gps_pos   - Right.gps_pos, 
               Left.baro_alt  - Right.baro_alt,
               Left.acc_ori   - Right.acc_ori,
               Left.gyr_rates - Right.gyr_rates );
   end "-";
   
   -------------------------
   --  calculate_gain
   -------------------------
   
   procedure calculate_gain( states : State_Vector; 
                             samples : Observation_Vector; 
                             dt : Time_Type;
                             K : out Kalman_Gain_Matrix;
                             residual : out Innovation_Vector) is
                             
      function measurement_transition( states : in State_Vector; dt : Time_Type ) return Observation_Vector is
         samples : Observation_Vector;
      begin
         samples.baro_alt := states.pos.Altitude;
         samples.gps_pos := states.pos;
         samples.gyr_rates := states.rates;
         samples.acc_ori := states.orientation;
         --samples.mag_ori := states.orientation;
         return samples;
      end measurement_transition;
      
      S : Innovation_Covariance_Matrix;
      
   begin
      -- estimate gain
      residual := samples - measurement_transition( states, dt );
      S := G.H * G.P * Transpose(G.H) + G.R;
      K := G.P * Transpose(G.H) * Inverse( S );
      
      -- save observation vector
      G.z := samples;
   end calculate_gain;
   
   -------------------------
   --  uptate_state
   -------------------------
   procedure uptate_state( states : in out State_Vector; 
                           K      : Kalman_Gain_Matrix; 
                           residual : Innovation_Vector; 
                           dt : Time_Type ) is
                           
      BIAS_LIMIT : constant Angular_Velocity_Type := 50.0 * Degree/Second;
   begin
      if dt > 0.0 then 
         -- update state
         states.pos.Longitude := states.pos.Longitude + K( map(X_LON), map(Z_LON) ) * residual.delta_gps_pos.Longitude;
         states.pos.Latitude := states.pos.Latitude + K( map(X_LAT), map(Z_LAT) ) * residual.delta_gps_pos.Latitude;
         states.pos.Altitude := states.pos.Altitude + K( map(X_ALT), map(Z_ALT) ) * residual.delta_gps_pos.Altitude
           + K( map(X_ALT), map(Z_BARO_ALT) ) * residual.delta_baro_alt;
                                                 
         states.orientation.Roll := wrap_Angle( states.orientation.Roll + K( map(X_ROLL), map(Z_ROLL) ) * residual.delta_acc_ori(X),
                                                Roll_Type'First, Roll_Type'Last );
         states.orientation.Pitch := mirror_Angle( states.orientation.Pitch + K( map(X_PITCH), map(Z_PITCH) ) * residual.delta_acc_ori(Y),
                                                   Pitch_Type'First, Pitch_Type'Last );
         states.orientation.Yaw := wrap_Angle( states.orientation.Yaw + K( map(X_YAW), map(Z_YAW) ) * residual.delta_acc_ori(Z),
                                               Yaw_Type'First, Yaw_Type'Last);
         states.rates(X) := states.rates(X) + K( map(X_ROLL_RATE), map(Z_ROLL_RATE) ) * residual.delta_gyr_rates(X);
         states.rates(Y) := states.rates(Y) + K( map(X_PITCH_RATE), map(Z_PITCH_RATE) ) * residual.delta_gyr_rates(Y);
         states.rates(Z) := states.rates(Z) + K( map(X_YAW_RATE), map(Z_YAW_RATE) ) * residual.delta_gyr_rates(Z);
         states.bias(X) := states.bias(X) + K( map(X_ROLL_BIAS), map(Z_ROLL) ) * residual.delta_acc_ori(X) / dt;
         states.bias(Y) := states.bias(Y) + K( map(X_PITCH_BIAS), map(Z_PITCH) ) * residual.delta_acc_ori(Y) / dt;
         states.bias(Z) := states.bias(Z) + K( map(X_YAW_BIAS), map(Z_YAW) ) * residual.delta_acc_ori(Z) / dt;
      
         Logger.log(Logger.DEBUG, "bX: " & AImage( states.bias(X)*Second ) & 
                      ", K_X: " & Image(  K( map(X_ROLL), map(Z_ROLL) ) ) &
                      ", GyrX: " & AImage(states.rates(X)*Second)
                   );
         Logger.log(Logger.DEBUG, "bY: " & AImage( states.bias(Y)*Second ) & 
                      ", K_Y: " & Image(  K( map(X_PITCH), map(Z_PITCH) ) ) &
                      ", GyrY: " & AImage(states.rates(Y)*Second)
                   );                
      
         -- limit bias
         for dim in Cartesian_Coordinates_Type loop
            if states.bias(dim) < -BIAS_LIMIT then
               states.bias(dim) := -BIAS_LIMIT;
            elsif states.bias(dim) > BIAS_LIMIT then
               states.bias(dim) := BIAS_LIMIT;
            end if;
         end loop;
      end if;
   end uptate_state;

   -------------------------
   --  update_cov
   -------------------------
   
   procedure update_cov( P : in out State_Covariance_Matrix; K :Kalman_Gain_Matrix ) is
   begin
      -- update cov
      P := P - (K * G.H) * P;
   end update_cov;

   -------------------------
   --  calculate_A
   -------------------------
   
   procedure calculate_A( A : out State_Transition_Matrix; dt : Time_Type ) is
   begin
      A := (others => (others => 0.0));
      A( map(X_LAT), map(X_LAT) ) := 1.0; A( map(X_LAT), map(X_GROUND_SPEED_X) ) := Unit_Type(dt);
      A( map(X_LON), map(X_LON) ) := 1.0; A( map(X_LON), map(X_GROUND_SPEED_Y) ) := Unit_Type(dt);
      A( map(X_ALT), map(X_ALT) ) := 1.0; A( map(X_ALT), map(X_GROUND_SPEED_Z) ) := -Unit_Type(dt);
   
      A( map(X_ROLL),  map(X_ROLL) )  := 1.0;   A( map(X_ROLL),  map(X_ROLL_RATE) )  := Unit_Type(dt);   A( map(X_ROLL),  map(X_ROLL_BIAS) )  := -Unit_Type(dt);
      A( map(X_PITCH), map(X_PITCH) ) := 1.0;   A( map(X_PITCH), map(X_PITCH_RATE) ) := Unit_Type(dt);   A( map(X_PITCH), map(X_PITCH_BIAS) ) := -Unit_Type(dt); 
      A( map(X_YAW),   map(X_YAW) )   := 1.0;   A( map(X_YAW),   map(X_YAW_RATE) )   := Unit_Type(dt);   A( map(X_YAW),   map(X_YAW_BIAS) )   := -Unit_Type(dt); 
      
      A( map(X_ROLL_RATE), map(X_ROLL_RATE) ) := 1.0;
      A( map(X_PITCH_RATE), map(X_PITCH_RATE) ) := 1.0;
      A( map(X_YAW_RATE), map(X_YAW_RATE) ) := 1.0;
      
      A( map(X_ROLL_BIAS), map(X_ROLL_BIAS) ) := 1.0;
      A( map(X_PITCH_BIAS), map(X_PITCH_BIAS) ) := 1.0;
      A( map(X_YAW_BIAS), map(X_YAW_BIAS) ) := 1.0;
      
      
      
   end calculate_A;

end Kalman;
