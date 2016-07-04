
with PX4IO.Driver;
with Servo;
with Generic_PID_Controller;
with Logger;
with Config.Software;
with Units.Numerics; use Units.Numerics;


with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;

with Helper;

package body Controller is

   package Pitch_PID_Controller is new Generic_PID_Controller(Pitch_Type,
                                                              Elevon_Angle_Type,
                                                              Unit_Type,
                                                              -100.0*Degree,
                                                              100.0*Degree,
                                                              Elevon_Angle_Type'First,
                                                              Elevon_Angle_Type'Last);
   PID_Pitch : Pitch_PID_Controller.Pid_Object;


   package Roll_PID_Controller is new Generic_PID_Controller(Roll_Type,
                                                             Aileron_Angle_Type,
                                                             Unit_Type,
                                                             -100.0*Degree,
                                                             100.0*Degree,
                                                             Aileron_Angle_Type'First,
                                                             Aileron_Angle_Type'Last);
   PID_Roll : Roll_PID_Controller.Pid_Object;






   G_Object_Orientation : Orientation_Type   := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
   G_Object_Position    : GPS_Loacation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);

   G_Target_Position    : GPS_Loacation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);

   G_Target_Orientation : Orientation_Type := (0.0 * Degree, -3.0 * Degree, 0.0 * Degree);




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

      Roll_PID_Controller.initialize(PID_Roll,
                                      Unit_Type( Config.Software.CFG_PID_ROLL_P ),
                                      Unit_Type( Config.Software.CFG_PID_ROLL_I ),
                                      Unit_Type( Config.Software.CFG_PID_ROLL_D ));

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
      G_Target_Orientation.Pitch := pitch;
   end set_Target_Pitch;

   procedure set_Current_Orientation (orientation : Orientation_Type) is
   begin
      G_Object_Orientation := orientation;
   end set_Current_Orientation;


   procedure runOneCycle is
   begin
      control_Pitch;
      control_Heading;
      control_Roll;

      G_Elevon_Angles := Elevon_Angles(G_Plane_Control.Elevator, G_Plane_Control.Aileron);

      Logger.log(Logger.DEBUG, "Elevons: " & AImage( G_Elevon_Angles(LEFT) ) & ", " & AImage( G_Elevon_Angles(RIGHT) ) );

      Servo.set_Angle(Servo.LEFT_ELEVON, G_Elevon_Angles(LEFT) );
      Servo.set_Angle(Servo.RIGHT_ELEVON, G_Elevon_Angles(RIGHT) );

      PX4IO.Driver.sync_Outputs;
   end runOneCycle;


   procedure detach is
   begin
      for i in Integer range 1 .. 3 loop
         Servo.set_Angle(Servo.LEFT_ELEVON, Elevon_Angle_Type'Last );
         Servo.set_Angle(Servo.RIGHT_ELEVON, Elevon_Angle_Type'Last );
         PX4IO.Driver.sync_Outputs;
         Helper.delay_ms( 2000 );
         Servo.set_Angle(Servo.LEFT_ELEVON, 0.0 * Degree);
         Servo.set_Angle(Servo.RIGHT_ELEVON, 0.0 * Degree);
         Helper.delay_ms( 2000 );
      end loop;
   end detach;

   procedure control_Pitch is
      error : constant Pitch_Type := ( G_Object_Orientation.Pitch - G_Target_Orientation.Pitch );
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type( Float( (now - G_Last_Call_Time) / Ada.Real_Time.Milliseconds(1) ) * 1.0e-3 );
   begin
      G_Last_Call_Time := now;
      G_Plane_Control.Elevator := Pitch_PID_Controller.step(PID_Pitch, error, dt);
   end control_Pitch;

   procedure control_Heading is
   begin
      G_Target_Orientation.Yaw := Yaw_Type( Heading( G_Object_Position,
                                                     G_Target_Position ) );

      -- G_Plane_Control.Aileron := Pitch_PID_Controller.step(PID_Pitch, error, dt);
   end control_Heading;

   procedure control_Roll is
      error : constant Roll_Type := ( G_Object_Orientation.Roll - G_Target_Orientation.Roll );
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type( Float( (now - G_Last_Call_Time) / Ada.Real_Time.Milliseconds(1) ) * 1.0e-3 );
   begin
      G_Plane_Control.Aileron := Roll_PID_Controller.step(PID_Roll, error, dt);
   end control_Roll;



   function Elevon_Angles( elevator : Elevator_Angle_Type; aileron : Aileron_Angle_Type ) return Elevon_Angle_Array is
      scale : constant Unit_Type := (Elevator_Angle_Type'Last + Aileron_Angle_Type'Last) / Elevon_Angle_Type'Last;
   begin
      return (LEFT => (elevator + aileron) / scale,
              RIGHT => (elevator - aileron) / scale);
   end Elevon_Angles;



   function delta_Angle(From : Angle_Type; To : Angle_Type) return Angle_Type is
      result : Angle_Type := To - From;
   begin
      if result > 180.0 * Degree then
         result := 180.0 * Degree - result;
      elsif result < -180.0 * Degree then
         result := result + 180.0 * Degree;
      end if;
      return result;
   end delta_Angle;

   -- 	θ = atan2( sin Δλ ⋅ cos φ2 , cos φ1 ⋅ sin φ2 − sin φ1 ⋅ cos φ2 ⋅ cos Δλ )
   -- φ is lat, λ is long
   function Heading(source_location : GPS_Loacation_Type;
                    target_location  : GPS_Loacation_Type)
                    return Heading_Type is
      result : Heading_Type := NORTH;
   begin
      if source_location.Longitude /= target_location.Longitude or source_location.Latitude /= target_location.Latitude then
         result := Arctan( Sin( delta_Angle( source_location.Longitude,
                                           target_location.Longitude ) ) *
                         Cos( target_location.Latitude ),
                         Cos( source_location.Latitude ) * Sin( target_location.Latitude ) -
                         Sin( source_location.Latitude ) * Sin( target_location.Latitude ) *
                         Cos( target_location.Latitude ) *
                         Cos( delta_Angle( source_location.Longitude,
                                      target_location.Longitude ) ),
                     DEGREE_360
                        );
      end if;
      return result;
   end Heading;


end Controller;
