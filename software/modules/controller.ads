-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
-- Module: Controller
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Controls all actuators, calls PID loop
-- 
-- ToDo:
-- [ ] Implementation

with Units; use Units;
with Units.Navigation; use Units.Navigation;

package Controller with SPARK_Mode is

   subtype Elevator_Angle_Type is Angle_Type range -43.0 * Degree .. 43.0 * Degree;
   subtype Aileron_Angle_Type  is Angle_Type range -43.0 * Degree .. 43.0 * Degree;   
   subtype Elevon_Angle_Type   is Angle_Type range -45.0 * Degree .. 45.0 * Degree;

   type Elevon_Index_Type is (LEFT, RIGHT);   
   type Elevon_Angle_Array is array(Elevon_Index_Type) of Elevon_Angle_Type;


   -- init
   procedure initialize;
        
   procedure activate;
        
   procedure deactivate;

   procedure set_Target_Position(location : GPS_Loacation_Type);
        
   procedure set_Current_Position(location : GPS_Loacation_Type);        
        
   procedure set_Current_Orientation (orientation : Orientation_Type);

   procedure log_Info;

   procedure runOneCycle;
   
   procedure set_hold;
   
   procedure set_detach;
   
   procedure bark;  -- good boy! 
   --  don't use this when time is critical. It will consume 400msec!
   
   procedure sync with Inline;
   
   function get_Elevons return Elevon_Angle_Array;

private
   
   type Control_Priority_Type is (EQUAL, PITCH_FIRST, ROLL_FIRST);

   type Plane_Control_Type is record
      Elevator : Elevator_Angle_Type;
      Aileron  : Aileron_Angle_Type;
   end record; 

   procedure control_Roll;
   
   procedure control_Pitch;
     

   function Elevon_Angles( elevator : Elevator_Angle_Type; aileron : Aileron_Angle_Type; priority : Control_Priority_Type ) return Elevon_Angle_Array;


end Controller;
