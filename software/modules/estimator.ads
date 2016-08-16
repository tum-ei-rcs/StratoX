-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Estimator
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Estimates state data like orientation and velocity
--
-- ToDo:
-- [ ] Implementation

with Units; use Units;
with Units.Vectors;    use Units.Vectors;
with Units.Navigation; use Units.Navigation;
with Interfaces;       use Interfaces;


with Kalman;

package Estimator with SPARK_Mode is

   -- init
   procedure initialize;

   -- fetch fresh measurement data
   procedure update( input : Kalman.Input_Vector );
   
   procedure reset_log_calls;
   
   procedure log_Info;
   
   procedure lock_Home(position : GPS_Loacation_Type; baro_height : Altitude_Type);
   
   function get_Orientation return Orientation_Type;
   
   function get_Position return GPS_Loacation_Type;
   
   function get_GPS_Fix return GPS_Fix_Type;
   
   function get_Num_Sat return Unsigned_8;
   
   function get_current_Height return Altitude_Type;
   
   function get_relative_Height return Altitude_Type;
  
   function get_max_Height return Altitude_Type;
   
   function get_Baro_Height return Altitude_Type;
   
   function get_Stable_Time return Time_Type;  
   



private
   function Orientation
     (acc_vector : Linear_Acceleration_Vector) return Orientation_Type;
   
   procedure update_Max_Height;
   
   procedure check_stable_Time;

   G_Object_Orientation : Orientation_Type   := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
   G_Object_Position    : GPS_Loacation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);
--     Object_Pose : Dynamics3D.Pose_Type := (
--        position => (0.0, 0.0, 0.0),
--        orientation => (others => 0.0) );
   

end Estimator;
