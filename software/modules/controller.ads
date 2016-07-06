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


   -- init
   procedure initialize;
        
   procedure activate;
        
   procedure deactivate;

   procedure set_Target_Position(location : GPS_Loacation_Type);
        
   procedure set_Current_Position(location : GPS_Loacation_Type);
        
   procedure set_Target_Pitch (pitch : Pitch_Type);
        
   procedure set_Current_Orientation (orientation : Orientation_Type);

   procedure runOneCycle;
   
   procedure detach;

private

   subtype Elevator_Angle_Type is Angle_Type range -22.0 * Degree .. 22.0 * Degree;
   subtype Aileron_Angle_Type  is Angle_Type range -22.0 * Degree .. 22.0 * Degree;   
   subtype Elevon_Angle_Type   is Angle_Type range -45.0 * Degree .. 45.0 * Degree;

   type Elevon_Index_Type is (LEFT, RIGHT);
   
   
   
   type Elevon_Angle_Array is array(Elevon_Index_Type) of Elevon_Angle_Type;

   type Plane_Control_Type is record
      Elevator : Elevator_Angle_Type;
      Aileron  : Aileron_Angle_Type;
   end record; 

   procedure control_Roll;
   
   procedure control_Pitch;
   
   procedure control_Yaw;

   function Elevon_Angles( elevator : Elevator_Angle_Type; aileron : Aileron_Angle_Type ) return Elevon_Angle_Array;

   function Heading(source_location : GPS_Loacation_Type;
                    target_location  : GPS_Loacation_Type)
                    return Heading_Type;

   function delta_Angle(From : Angle_Type; To : Angle_Type) return Angle_Type;

end Controller;
