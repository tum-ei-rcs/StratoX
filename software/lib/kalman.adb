
with Ada.Real_Time; use Ada.Real_Time;

with Ada.Numerics.Generic_Real_Arrays;
with Units.Vectors; use Units.Vectors.Unit_Arrays_Pack;

package body Kalman with SPARK_Mode,
Refined_State => (State => G)
is

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



   G : Global_Type;




   procedure reset is 
   begin
      G.A := (others => (others => 0.0));
      G.H := (others => (others => 0.0));
      
      
      G.H(1 .. 3, 1 .. 3) := Ones(3);  -- position
      
   
   
   
   end reset;

   procedure perform_Filter_Step( u : in Input_Vector; z : in Observation_Vector ) is
      now : Time := Clock;
      dt : Time_Type := To_Time(now - G.t_last);
   begin
      predict(u, dt);
      update(z, dt);
   end perform_Filter_Step;


   procedure predict(u : Input_Vector; dt : Time_Type) is 
   begin
      predict_state( G.x, u, dt );
      predict_cov( G.P, G.Q );
   end predict;


   procedure update(z : Observation_Vector; dt : Time_Type) is
   begin
      uptate_state( G.x, z, dt );
      update_cov( G.P, dt );
   end update;


   procedure predict_state( state : in out State_Vector; input : Input_Vector; dt : Time_Type ) is
      new_state : State_Vector := state;
      
      ELEVON_TO_GYRO : constant Frequency_Type := 0.5 * Hertz;
      PITCH_TO_AIRSPEED : constant := 0.5 * Meter / ( Degree * Second );
      compensated_rates : Angular_Velocity_Vector := state.rates;
   begin
      -- gyro compensation
      rotate( Cartesian_Vector_Type( compensated_rates ), X , state.orientation.Roll );
   
      -- state prediction
      new_state.orientation := state.orientation + (state.rates - state.bias) * dt;
      new_state.rates(X) := input.Aileron * ELEVON_TO_GYRO;
      new_state.rates(Y) := input.Elevator * ELEVON_TO_GYRO;
      new_state.pos := state.pos + state.ground_speed * dt;
      new_state.air_speed(X) := state.air_speed(X) - state.orientation.Pitch * PITCH_TO_AIRSPEED;
   end predict_state;   


   procedure predict_cov( P : in out State_Covariance_Matrix; Q : State_Noise_Covariance_Matrix ) is
   begin
      P := G.A * P * Transpose(G.A) + Q;
   end predict_cov;


   procedure uptate_state( states : in out State_Vector; samples : Observation_Vector; dt : Time_Type ) is
   
      function measurement_transition( states : in out State_Vector; dt : Time_Type ) return Observation_Vector is
         samples : Observation_Vector;
      begin
         samples.baro_alt := states.pos.Altitude;
         samples.gps_pos := states.pos;
         samples.gyr_rates := states.rates;
         samples.acc_ori := states.orientation;
         --samples.mag_ori := states.orientation;
         return samples;
      end measurement_transition;
      
      y : Innovation_Vector;
      S : Innovation_Covariance_Matrix;
      K : Kalman_Gain_Matrix;
      
   begin
      -- estimate gain
      y := samples - measurement_transition( states, dt );
      S := G.H * G.P * Transpose(G.H) + G.R;
      K := G.P * Transpose(G.H) * Inverse( S );
      
      -- update state
      states.pos.Longitude := states.pos.Longitude;
      
      -- update cov
      G.P := G.P - (K * G.H) * G.P;  
      
   end uptate_state;

   procedure update_cov( P : in out State_Covariance_Matrix; dt : Time_Type ) is
   begin
      null;
   end update_cov;


end Kalman;
