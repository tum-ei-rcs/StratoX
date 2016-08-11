
with PX4IO.Driver;
with Servo;
with Generic_PID_Controller;
with Logger;
with Profiler;
with Config.Software;
with Units.Numerics; use Units.Numerics;

with ULog;


with Ada.Real_Time; use Ada.Real_Time;
pragma Elaborate_All(Ada.Real_Time);

with Helper;

package body Controller with SPARK_Mode is

   type Logger_Call_Type is mod Config.Software.CFG_LOGGER_CALL_SKIP with Default_Value => 0;

   type State_Type is record
      logger_calls : Logger_Call_Type;
      logger_console_calls : Logger_Call_Type;
      control_profiler : Profiler.Profile_Tag;
      distance_to_target : Length_Type;
   end record;

   package Pitch_PID_Controller is new Generic_PID_Controller(Angle_Type,
                                                              Elevator_Angle_Type,
                                                              Unit_Type,
                                                              -50.0*Degree,
                                                              50.0*Degree,
                                                              Elevator_Angle_Type'First,
                                                              Elevator_Angle_Type'Last);
   PID_Pitch : Pitch_PID_Controller.Pid_Object;


   package Roll_PID_Controller is new Generic_PID_Controller(Angle_Type,
                                                             Aileron_Angle_Type,
                                                             Unit_Type,
                                                             -50.0*Degree,
                                                             50.0*Degree,
                                                             Aileron_Angle_Type'First,
                                                             Aileron_Angle_Type'Last);
   PID_Roll : Roll_PID_Controller.Pid_Object;


   package Yaw_PID_Controller is new Generic_PID_Controller( Angle_Type,
                                                             Roll_Type,
                                                             Unit_Type,
                                                             -50.0*Degree,
                                                             50.0*Degree,
                                                             -Config.Software.CFG_TARGET_ROLL_LIMIT,
                                                             Config.Software.CFG_TARGET_ROLL_LIMIT);
   PID_Yaw : Yaw_PID_Controller.Pid_Object;




   G_Object_Orientation : Orientation_Type   := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
   G_Object_Position    : GPS_Loacation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);

   G_Target_Position    : GPS_Loacation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);

   G_Target_Orientation : Orientation_Type := (0.0 * Degree, -3.0 * Degree, 0.0 * Degree);


   G_state : State_Type;

   G_Last_Call_Time : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   G_Last_Roll_Control : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   G_Last_Yaw_Control : Ada.Real_Time.Time := Ada.Real_Time.Clock;


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

      Yaw_PID_Controller.initialize(PID_Yaw,
                                      Unit_Type( Config.Software.CFG_PID_YAW_P ),
                                      Unit_Type( Config.Software.CFG_PID_YAW_I ),
                                      Unit_Type( Config.Software.CFG_PID_YAW_D ));


      G_state.control_profiler.init("Control");
      Logger.log(Logger.DEBUG, "Controller initialized");

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


   procedure log_Info is
      controller_msg : ULog.Message (Typ => ULog.CONTROLLER);
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      G_state.logger_console_calls := Logger_Call_Type'Succ( G_state.logger_console_calls );
      if G_state.logger_console_calls = 0 then
         Logger.log_console(Logger.DEBUG,
                            "Home L" & AImage( G_Target_Position.Longitude ) &
                            ", " & AImage( G_Target_Position.Latitude ) &
                            ", " & Image( G_Target_Position.Altitude ) );
         Logger.log_console(Logger.DEBUG,
                            "TY: " & AImage( G_Target_Orientation.Yaw ) &
                            ", TR: " & AImage( G_Target_Orientation.Roll ) &
                            "   Elev: " & AImage( G_Elevon_Angles(LEFT) ) & ", " & AImage( G_Elevon_Angles(RIGHT) )
                           );
         G_state.control_profiler.log;
      end if;

      -- log to SD
      controller_msg := ( Typ => ULog.CONTROLLER,
                          t => now,
                          target_yaw => Float( G_Target_Orientation.Yaw ),
                          target_roll => Float( G_Target_Orientation.Roll ),
                          elevon_left => Float( G_Elevon_Angles(LEFT) ),
                          elevon_right => Float( G_Elevon_Angles(RIGHT) ) );
      Logger.log_sd( Logger.INFO, controller_msg );



   end log_Info;


   procedure set_hold is
   begin
      -- hold glider in position
      Servo.set_Angle(Servo.LEFT_ELEVON, 35.0 * Degree );
      Servo.set_Angle(Servo.RIGHT_ELEVON, 35.0 * Degree );
      PX4IO.Driver.sync_Outputs;
   end set_hold;


   procedure detach is
   begin
      Servo.set_Angle(Servo.LEFT_ELEVON, -40.0 * Degree);
      Servo.set_Angle(Servo.RIGHT_ELEVON, -40.0 * Degree);
      for k in Integer range 1 .. 80 loop
         PX4IO.Driver.sync_Outputs;
         Helper.delay_ms( 10 );
      end loop;
      Servo.set_Angle(Servo.LEFT_ELEVON, 20.0 *Degree );
      Servo.set_Angle(Servo.RIGHT_ELEVON, 20.0 *Degree );
      for k in Integer range 1 .. 30 loop
         PX4IO.Driver.sync_Outputs;
         Helper.delay_ms( 10 );
      end loop;
      Servo.set_Angle(Servo.LEFT_ELEVON, -40.0 * Degree);
      Servo.set_Angle(Servo.RIGHT_ELEVON, -40.0 * Degree);
      for k in Integer range 1 .. 30 loop
         PX4IO.Driver.sync_Outputs;
         Helper.delay_ms( 10 );
      end loop;
   end detach;


   procedure control_Roll is
      error : constant Angle_Type := ( G_Target_Orientation.Roll - G_Object_Orientation.Roll );
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type( Float( (now - G_Last_Roll_Control) / Ada.Real_Time.Milliseconds(1) ) * 1.0e-3 );
   begin
      G_Last_Roll_Control := now;
      Roll_PID_Controller.step(PID_Roll, error, dt, G_Plane_Control.Aileron);
   end control_Roll;


   procedure control_Pitch is
      error : constant Angle_Type := ( G_Target_Orientation.Pitch - G_Object_Orientation.Pitch );
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type( Float( (now - G_Last_Call_Time) / Ada.Real_Time.Milliseconds(1) ) * 1.0e-3 );
   begin
      G_Last_Call_Time := now;
      Pitch_PID_Controller.step(PID_Pitch, error, dt, G_Plane_Control.Elevator);
   end control_Pitch;


   function delta_Angle(From : Angle_Type; To : Angle_Type) return Angle_Type is
      result : Angle_Type := To - From;
   begin
      if result > 180.0 * Degree then
         result := result - 360.0 * Degree;
      elsif result < -180.0 * Degree then
         result := result + 360.0 * Degree;
      end if;
      return result;
   end delta_Angle;


   -- 	θ = atan2( sin Δλ ⋅ cos φ2 , cos φ1 ⋅ sin φ2 − sin φ1 ⋅ cos φ2 ⋅ cos Δλ )
   -- φ is lat, λ is long
   function Heading(source_location : GPS_Loacation_Type;
                    target_location  : GPS_Loacation_Type)
                    return Heading_Type is
      result : Angle_Type := 0.0 * Degree;
   begin
      if source_location.Longitude /= target_location.Longitude or source_location.Latitude /= target_location.Latitude then
--           Logger.log_console(Logger.TRACE, "Calculating Heading: ");
--           Logger.log_console(Logger.TRACE,
--                      "Source LLA" & AImage( source_location.Longitude ) &
--                   ", " & AImage( source_location.Latitude ) &
--                   ", " & Image( source_location.Altitude ) );
--                    Logger.log_console(Logger.TRACE,
--                      "Target LLA" & AImage( target_location.Longitude ) &
--                   ", " & AImage( target_location.Latitude ) &
--                   ", " & Image( target_location.Altitude ) );
         result := Arctan( Sin( delta_Angle( source_location.Longitude,
                                           target_location.Longitude ) ) *
                         Cos( target_location.Latitude ),
                         Cos( source_location.Latitude ) * Sin( target_location.Latitude ) -
                         Sin( source_location.Latitude ) * Cos( target_location.Latitude ) *
                         Cos( delta_Angle( source_location.Longitude,
                                      target_location.Longitude ) ),
                     DEGREE_360
                        );
      end if;

      -- Constrain to Heading_Type
      if result < 0.0 * Degree then
         result := result + Heading_Type'Last;
      end if;
      return Heading_Type( result );
   end Heading;

   procedure control_Yaw is
      error : Angle_Type := 0.0 *Degree;
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type( Float( (now - G_Last_Yaw_Control) / Ada.Real_Time.Milliseconds(1) ) * 1.0e-3 );
   begin
      if G_Target_Position.Longitude /= 0.0 * Degree and G_Target_Position.Latitude /= 0.0 * Degree then

         G_state.distance_to_target := Distance( G_Object_Position, G_Target_Position );

         -- Logger.log( Logger.INFO, " Distance: " & Integer'Image( Integer( G_state.distance_to_target )) );

         if G_state.distance_to_target > Config.TARGET_AREA_RADIUS then
            G_Last_Yaw_Control := now;
            G_Target_Orientation.Yaw := Yaw_Type( Heading( G_Object_Position,
                                                  G_Target_Position ) );

            error := delta_Angle( G_Object_Orientation.Yaw, G_Target_Orientation.Yaw );

            Yaw_PID_Controller.step(PID_Yaw, error, dt, G_Target_Orientation.Roll);
         else
            G_Target_Orientation.Roll := Config.CIRCLE_TRAJECTORY_ROLL;
         end if;
      else
         G_Target_Orientation.Roll := Config.CIRCLE_TRAJECTORY_ROLL;
      end if;
   end control_Yaw;


   function Elevon_Angles( elevator : Elevator_Angle_Type; aileron : Aileron_Angle_Type;
                           priority : Control_Priority_Type ) return Elevon_Angle_Array is
      balance : Float range 0.0 .. 2.0 := 1.0;
      scale : Float range 0.0 .. 1.0 := 1.0;
      balanced_elevator : Elevator_Angle_Type;
      balanced_aileron  : Aileron_Angle_Type;

   begin
      -- dynamic balancing
      case (priority) is
         when EQUAL => balance := 1.0;
         when PITCH_FIRST => balance := 1.3;
         when ROLL_FIRST => balance := 0.7;
      end case;
      balanced_elevator := Elevator_Angle_Type( Helper.Saturate( Float(elevator) * balance,
                                                Float(Elevator_Angle_Type'First), Float(Elevator_Angle_Type'Last)) );
      balanced_aileron  := Aileron_Angle_Type( Helper.Saturate( Float(aileron) * (2.0 - balance),
                                               Float(Aileron_Angle_Type'First), Float(Aileron_Angle_Type'Last)) );

      -- scaling (only if necessary)
      if abs(balanced_elevator) + abs(balanced_aileron) > Elevon_Angle_Type'Last then
         scale := 0.95 * Float(Elevon_Angle_Type'Last) / ( abs(Float(balanced_elevator)) + abs(Float(balanced_aileron)) );
      end if;

      -- mixing
      return (LEFT  => (balanced_elevator - balanced_aileron) * Unit_Type(scale),
              RIGHT => (balanced_elevator + balanced_aileron) * Unit_Type(scale));
   end Elevon_Angles;


   procedure runOneCycle is
      Control_Priority : Control_Priority_Type := EQUAL;
   begin

      -- control
      control_Pitch;
      --control_Yaw;
      G_Target_Orientation.Roll := Config.CIRCLE_TRAJECTORY_ROLL;  -- TEST: Omakurve
      control_Roll;

      G_state.control_profiler.start;

      -- mix
      if abs( G_Object_Orientation.Roll ) > 90.0 * Degree then
         Control_Priority := ROLL_FIRST;
      end if;
      if abs( G_Object_Orientation.Pitch ) > 40.0 *Degree then
         Control_Priority := PITCH_FIRST;
      end if;
      G_Elevon_Angles := Elevon_Angles(G_Plane_Control.Elevator, G_Plane_Control.Aileron, Control_Priority);


      -- set servos
      Servo.set_Angle(Servo.LEFT_ELEVON, G_Elevon_Angles(LEFT) );
      Servo.set_Angle(Servo.RIGHT_ELEVON, G_Elevon_Angles(RIGHT) );

      -- Output
      PX4IO.Driver.sync_Outputs;

      G_state.control_profiler.stop;

      -- log
      G_state.logger_calls := Logger_Call_Type'Succ( G_state.logger_calls );
      if G_state.logger_calls = 0 then
         log_Info;
      end if;




   end runOneCycle;

end Controller;
