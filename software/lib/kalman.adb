
with Ada.Real_Time; use Ada.Real_Time;

with Ada.Numerics.Generic_Real_Arrays;
with Units.Vectors; use Units.Vectors.Unit_Arrays_Pack;

package body Kalman with SPARK_Mode,
Refined_State => (State => G)
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



   G : Global_Type;




   procedure reset is 
      now : Time := Clock;
   begin
      G.t_last := now;
   
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
      G.H( map(Z_ROLL_RATE) , map(X_ROLL_BIAS) )  := -1.0;
      G.H( map(Z_PITCH_RATE), map(X_PITCH_BIAS) ) := -1.0;
      G.H( map(Z_YAW_RATE)  , map(X_YAW_BIAS) )   := -1.0;
      
      
      -- Set A, Dynamic Matrix
      declare
         A : State_Transition_Matrix;
         --  avoid forbidden aliasing by copying the result into G after the call (SPARK RM 6.4.2)
      begin
         calculate_A( A, 0.0 * Second);
         G.A := A;
      end;

      -- Set P, Covariance Matrix
      G.P := Ones( k );
      
      -- Process Noise
      G.Q := Ones( k );
      
      -- Measurement Noise
      G.R := Ones( m );
      
      
   end reset;

   procedure perform_Filter_Step( u : in Input_Vector; z : in Observation_Vector ) is
      now : Time := Clock;
      dt : Time_Type := To_Time(now - G.t_last);
   begin
      predict(u, dt);
      update(z, dt);
      G.t_last := now;          
   end perform_Filter_Step;


   procedure predict(u : Input_Vector; dt : Time_Type) is 
   begin
      predict_state( G.x, u, dt );
      declare
         P : State_Covariance_Matrix;
         --  avoid forbidden aliasing by copying the result into G after the call (SPARK RM 6.4.2)
      begin         
         predict_cov( P, G.Q );
         G.P := P;
      end;
   end predict;


   procedure update(z : Observation_Vector; dt : Time_Type) is
   begin
      declare
         x : State_Vector;
      begin
         uptate_state( x, z, dt );
         G.x := x;
      end;
      update_cov( G.P, dt );
   end update;


   function get_States return State_Vector is
   begin
      return G.x;
   end get_States;
   
   
   
   
   procedure predict_state( state : in out State_Vector; input : Input_Vector; dt : Time_Type ) is
      new_state : State_Vector := state;
      
      ELEVON_TO_GYRO : constant Frequency_Type := 0.5 * Hertz;
      PITCH_TO_AIRSPEED : constant := 0.5 * Meter / ( Degree * Second );
      compensated_rates : Angular_Velocity_Vector := state.rates;
   begin
      -- gyro compensation
      -- rotate( Cartesian_Vector_Type( compensated_rates ), X , state.orientation.Roll );
   
      -- state prediction
      new_state.orientation := state.orientation + (state.rates - state.bias) * dt;
      new_state.rates(X) := input.Aileron * ELEVON_TO_GYRO;
      new_state.rates(Y) := input.Elevator * ELEVON_TO_GYRO;
      new_state.pos := state.pos; -- + state.ground_speed * dt;
      new_state.air_speed(X) := state.air_speed(X) - state.orientation.Pitch * PITCH_TO_AIRSPEED;
      -- FIXME: new_state is never used, and state is not written.
   end predict_state;   


   procedure predict_cov( P : in out State_Covariance_Matrix; Q : State_Noise_Covariance_Matrix ) is
   begin
      P := G.A * P * Transpose(G.A) + Q;
   end predict_cov;


   procedure uptate_state( states : in out State_Vector; samples : Observation_Vector; dt : Time_Type ) is
   
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
      
      residual : Innovation_Vector;
      S : Innovation_Covariance_Matrix;
      K : Kalman_Gain_Matrix;
      
   begin
      -- estimate gain
      residual := samples - measurement_transition( states, dt );
      S := G.H * G.P * Transpose(G.H) + G.R;
      K := G.P * Transpose(G.H) * Inverse( S );
      
      -- update state
      states.pos.Longitude := states.pos.Longitude + K( map(X_LON), map(Z_LON) ) * residual.delta_gps_pos.Longitude;
      states.pos.Latitude := states.pos.Latitude + K( map(X_LAT), map(Z_LAT) ) * residual.delta_gps_pos.Latitude;
      states.pos.Altitude := states.pos.Altitude + K( map(X_ALT), map(Z_ALT) ) * residual.delta_gps_pos.Altitude;
      states.orientation.Roll := states.orientation.Roll + K( map(X_ROLL), map(Z_ROLL) ) * residual.delta_acc_ori(X);
      states.orientation.Pitch := states.orientation.Pitch + K( map(X_PITCH), map(Z_PITCH) ) * residual.delta_acc_ori(Y);
      states.orientation.Yaw := states.orientation.Yaw + K( map(X_YAW), map(Z_YAW) ) * residual.delta_acc_ori(Z);
      states.rates(X) := states.rates(X) + K( map(X_ROLL_RATE), map(Z_ROLL_RATE) ) * residual.delta_gyr_rates(X);
      states.rates(Y) := states.rates(Y) + K( map(X_PITCH_RATE), map(Z_PITCH_RATE) ) * residual.delta_gyr_rates(Y);
      states.rates(Z) := states.rates(Z) + K( map(X_YAW_RATE), map(Z_YAW_RATE) ) * residual.delta_gyr_rates(Z);
      states.bias(X) := states.bias(X) + K( map(X_ROLL_BIAS), map(Z_ROLL_RATE) ) * residual.delta_gyr_rates(X);
      states.bias(Y) := states.bias(Y) + K( map(X_PITCH_BIAS), map(Z_PITCH_RATE) ) * residual.delta_gyr_rates(Y);
      states.bias(Z) := states.bias(Z) + K( map(X_YAW_BIAS), map(Z_YAW_RATE) ) * residual.delta_gyr_rates(Z);
      
      
      -- update cov
      G.P := G.P - (K * G.H) * G.P;  
      
   end uptate_state;

   procedure update_cov( P : in out State_Covariance_Matrix; dt : Time_Type ) is
      pragma Unreferenced (P);
   begin
      null;
   end update_cov;


   function "-"(Left, Right : Observation_Vector) return Innovation_Vector is
   begin
      return ( Left.gps_pos   - Right.gps_pos, 
               Left.baro_alt  - Right.baro_alt,
               Left.acc_ori   - Right.acc_ori,
               Left.gyr_rates - Right.gyr_rates );
   end "-";
   
   
   procedure calculate_A( A : out State_Transition_Matrix; dt : Time_Type ) is
   begin
      A := (others => (others => 0.0));
      A( map(X_LAT), map(X_LAT) ) := 1.0; G.A( map(X_LAT), map(X_GROUND_SPEED_X) ) := Unit_Type(dt);
      A( map(X_LON), map(X_LON) ) := 1.0; G.A( map(X_LON), map(X_GROUND_SPEED_Y) ) := Unit_Type(dt);
      A( map(X_ALT), map(X_ALT) ) := 1.0; G.A( map(X_ALT), map(X_GROUND_SPEED_Z) ) := -Unit_Type(dt);
   
      A( map(X_ROLL),  map(X_ROLL) )  := 1.0;   G.A( map(X_ROLL),  map(X_ROLL_RATE) )  := Unit_Type(dt);   G.A( map(X_ROLL),  map(X_ROLL_BIAS) )  := -1.0;
      A( map(X_PITCH), map(X_PITCH) ) := 1.0;   G.A( map(X_PITCH), map(X_PITCH_RATE) ) := Unit_Type(dt);   G.A( map(X_PITCH), map(X_PITCH_BIAS) ) := -1.0; 
      A( map(X_YAW),   map(X_YAW) )   := 1.0;   G.A( map(X_YAW),   map(X_YAW_RATE) )   := Unit_Type(dt);   G.A( map(X_YAW),   map(X_YAW_BIAS) )   := -1.0; 
      
      A( map(X_ROLL_RATE), map(X_ROLL_RATE) ) := 1.0;
      A( map(X_PITCH_RATE), map(X_PITCH_RATE) ) := 1.0;
      A( map(X_YAW_RATE), map(X_PITCH_RATE) ) := 1.0;
      
   end calculate_A;

end Kalman;
