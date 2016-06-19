
with PX4IO.Driver;
with Servo;
with Generic_PID_Controller;
with Logger;
with Config.Software;

with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;

package body Controller is

   package Pitch_PID_Controller is new Generic_PID_Controller(Pitch_Type,
                                                              Elevon_Angle_Type,
                                                              Unit_Type,
                                                              -100.0*Degree,
                                                              100.0*Degree,
                                                              Elevon_Angle_Type'First,
                                                              Elevon_Angle_Type'Last);

   PID_Pitch : Pitch_PID_Controller.Pid_Object;


   G_Object_Orientation : Orientation_Type   := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
   G_Object_Position    : GPS_Loacation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);

   G_Target_Position    : GPS_Loacation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);


   G_Target_Pitch : Pitch_Type := -3.0 * Degree;

   G_Last_Call_Time : Ada.Real_Time.Time := Ada.Real_Time.Clock;


   G_Plane_Control : Plane_Control_Type := (others => 0.0 * Degree);
   G_Elevon_Angles : Elevon_Angle_Array := (others => 0.0 * Degree);

   -- init
   procedure initialize is
   begin
      Servo.initialize;
      Pitch_PID_Controller.initialize(PID_Pitch,
                                      Unit_Type( Config.Software.CFG_PID_PITCH_P ),
                                      Unit_Type( Config.Software.CFG_PID_PITCH_I ),
                                      Unit_Type( Config.Software.CFG_PID_PITCH_D ));
   end initialize;


   procedure activate is
   begin
      Servo.activate;
   end activate;


   procedure deactivate is
   begin
      Servo.deactivate;
   end deactivate;


   procedure set_Current_Position(location : GPS_Loacation_Type) is
   begin
      G_Object_Position := location;
   end set_Current_Position;


   procedure set_Target_Position (location : GPS_Loacation_Type) is
   begin
      G_Target_Position := location;
   end set_Target_Position;


   procedure set_Target_Pitch (pitch : Pitch_Type) is
   begin
      G_Target_Pitch := pitch;
   end set_Target_Pitch;

   procedure set_Current_Orientation (orientation : Orientation_Type) is
   begin
      G_Object_Orientation := orientation;
   end set_Current_Orientation;


   procedure runOneCycle is
      elevons : Elevon_Angle_Array;
   begin
      control_Pitch;
      control_Heading;

      elevons := Elevon_Angles(G_Plane_Control.Elevator, G_Plane_Control.Aileron);

      Logger.log(Logger.DEBUG, "Elevons: " & AImage( elevons(LEFT) ) & ", " & AImage( elevons(RIGHT) ) );

      Servo.set_Angle(Servo.LEFT_ELEVON, elevons(LEFT) );
      Servo.set_Angle(Servo.RIGHT_ELEVON, elevons(RIGHT) );

      PX4IO.Driver.sync_Outputs;
   end runOneCycle;




   procedure control_Pitch is
      error : Pitch_Type := ( G_Object_Orientation.Pitch - G_Target_Pitch );
      now   : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt : Time_Type := Time_Type( Float( (now - G_Last_Call_Time) / Ada.Real_Time.Milliseconds(1) ) * 1.0e-3 );
   begin
      G_Last_Call_Time := now;
      G_Plane_Control.Elevator := Pitch_PID_Controller.step(PID_Pitch, error, dt);
   end control_Pitch;

   procedure control_Heading is
   begin
      null;
      -- G_Plane_Control.Aileron := Pitch_PID_Controller.step(PID_Pitch, error, dt);
   end control_Heading;


   function Elevon_Angles( elevator : Elevator_Angle_Type; aileron : Aileron_Angle_Type ) return Elevon_Angle_Array is
      scale : Unit_Type := (Elevator_Angle_Type'Last + Aileron_Angle_Type'Last) / Elevon_Angle_Type'Last;
   begin
      return (LEFT => (elevator + aileron) / scale,
              RIGHT => (elevator - aileron) / scale);
   end Elevon_Angles;



end Controller;
