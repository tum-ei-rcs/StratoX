
with PX4IO.Driver;
with Servo;
with Generic_PID_Controller;
with Logger;
with Profiler;
with Config.Software; use Config.Software;
with Units.Numerics; use Units.Numerics;
with Ada.Numerics.Elementary_Functions;
with Bounded_Image; use Bounded_Image;
with ULog;


with Ada.Real_Time; use Ada.Real_Time;
pragma Elaborate_All(Ada.Real_Time);

with Helper;

package body Controller with SPARK_Mode is

   --------------------
   --  TYPES
   --------------------

   type Logger_Call_Type is mod Config.Software.CFG_LOGGER_CALL_SKIP with Default_Value => 0;

   type State_Type is record
      logger_calls : Logger_Call_Type;
      logger_console_calls : Logger_Call_Type;
      control_profiler : Profiler.Profile_Tag;
      distance_to_target : Length_Type := 0.0 * Meter;
      detach_animation_time : Time_Type := 0.0 * Second;
      once_had_my_pos : Boolean := False;
   end record;

   --------------------
   --  STATES
   --------------------

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
                                                             -Config.MAX_ROLL,
                                                             Config.MAX_ROLL);
   PID_Yaw : Yaw_PID_Controller.Pid_Object;




   G_Object_Orientation : Orientation_Type   := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
   G_Object_Position    : GPS_Loacation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);

   G_Target_Position    : GPS_Loacation_Type := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);

   G_Target_Orientation : Orientation_Type := (0.0 * Degree, Config.TARGET_PITCH, 0.0 * Degree);


   G_state : State_Type;

   G_Last_Pitch_Control : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   G_Last_Roll_Control : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   G_Last_Yaw_Control : Ada.Real_Time.Time := Ada.Real_Time.Clock;


   G_Plane_Control : Plane_Control_Type := (others => 0.0 * Degree);
   G_Elevon_Angles : Elevon_Angle_Array := (others => 0.0 * Degree);

   --------------------
   --  PROTOTYPES
   --------------------

   procedure Limit_Target_Attitude with Inline;
   procedure Compute_Target_Pitch with Inline, Pre => True;
   function Have_My_Position return Boolean;
   function Have_Home_Position return Boolean;
   procedure Compute_Target_Roll with
     Contract_Cases => (not Have_My_Position => G_Target_Orientation.Yaw = G_Target_Orientation.Yaw'Old,
                        others => True);

   --------------------
   --  BODIES
   --------------------


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
      Logger.log (Logger.SENSOR, "Home=" & Integer_Img ( Integer (100000.0 * To_Degree (G_Target_Position.Latitude)))
                  & ", " & Integer_Img ( Integer (100000.0 * To_Degree (G_Target_Position.Longitude)))
                  & ", " & Integer_Img ( Sat_Cast_Int ( Float (G_Target_Position.Altitude))));
   end set_Target_Position;

   procedure set_Current_Orientation (orientation : Orientation_Type) is
   begin
      G_Object_Orientation := orientation;
   end set_Current_Orientation;


   procedure log_Info is
      controller_msg : ULog.Message (Typ => ULog.CONTROLLER);
      nav_msg : ULog.Message (Typ => ULog.NAV);
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;

      function Sat_Sub_Alt is new Saturated_Subtraction (Altitude_Type);
   begin
      G_state.logger_console_calls := Logger_Call_Type'Succ( G_state.logger_console_calls );
      if G_state.logger_console_calls = 0 then
         Logger.log_console(Logger.DEBUG,
                            "Home L" & AImage( G_Target_Position.Longitude ) &
                              ", " & AImage( G_Target_Position.Latitude ) &
                              ", " & Image( G_Target_Position.Altitude ) &
                              ", d=" & Integer_Img (Sat_Cast_Int ( Float (G_state.distance_to_target))) &
                              ", crs=" & AImage (G_Target_Orientation.Yaw));

         Logger.log_console(Logger.DEBUG,
                            "TY: " & AImage( G_Target_Orientation.Yaw ) &
                            ", TR: " & AImage( G_Target_Orientation.Roll ) &
                            "   Elev: " & AImage( G_Elevon_Angles(LEFT) ) & ", " & AImage( G_Elevon_Angles(RIGHT) )
                           );
      end if;

      -- log to SD
      controller_msg := ( Typ => ULog.CONTROLLER,
                          t => now,
                          target_yaw => Float( G_Target_Orientation.Yaw ),
                          target_roll => Float( G_Target_Orientation.Roll ),
                          elevon_left => Float( G_Elevon_Angles(LEFT) ),
                          elevon_right => Float( G_Elevon_Angles(RIGHT) ) );
      nav_msg := ( Typ => ULog.NAV,
                   t=> now,
                   home_dist => Float (G_state.distance_to_target),
                   home_course => Float (G_Target_Orientation.Yaw),
                   home_altdiff => Float (Sat_Sub_Alt (G_Object_Position.Altitude, G_Target_Position.Altitude)));
      Logger.log_sd (Logger.INFO, controller_msg);
      Logger.log_sd (Logger.SENSOR, nav_msg);

   end log_Info;



   procedure set_hold is
   begin
      -- hold glider in position
      Servo.set_Angle(Servo.LEFT_ELEVON, 38.0 * Degree );
      Servo.set_Angle(Servo.RIGHT_ELEVON, 38.0 * Degree );
   end set_hold;



   procedure set_detach is
   begin
      Servo.set_Angle(Servo.LEFT_ELEVON, -40.0 * Degree );
      Servo.set_Angle(Servo.RIGHT_ELEVON, -40.0 * Degree );
   end set_detach;



   procedure sync is
   begin
      PX4IO.Driver.sync_Outputs;
   end sync;



   procedure bark is
      angle : constant Servo.Servo_Angle_Type := 35.0 * Degree;
   begin
      for k in Integer range 1 .. 20 loop
         Servo.set_Angle(Servo.LEFT_ELEVON, angle);
         Servo.set_Angle(Servo.RIGHT_ELEVON, angle);
         PX4IO.Driver.sync_Outputs;
         Helper.delay_ms( 10 );
      end loop;
      for k in Integer range 1 .. 20 loop
         Servo.set_Angle(Servo.LEFT_ELEVON, angle+3.0*Degree);
         Servo.set_Angle(Servo.RIGHT_ELEVON, angle+3.0*Degree);
         PX4IO.Driver.sync_Outputs;
         Helper.delay_ms( 10 );
      end loop;
   end bark;



   procedure control_Roll is
      error : constant Angle_Type := ( G_Target_Orientation.Roll - G_Object_Orientation.Roll );
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type( Float( (now - G_Last_Roll_Control) / Ada.Real_Time.Milliseconds(1) ) * 1.0e-3 );
   begin
      G_Last_Roll_Control := now;
      Roll_PID_Controller.step (PID_Roll, error, dt, G_Plane_Control.Aileron);
   end control_Roll;



   procedure control_Pitch is
      error : constant Angle_Type := ( G_Target_Orientation.Pitch - G_Object_Orientation.Pitch );
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type( Float( (now - G_Last_Pitch_Control) / Ada.Real_Time.Milliseconds(1) ) * 1.0e-3 );
   begin
      G_Last_Pitch_Control := now;
      Pitch_PID_Controller.step(PID_Pitch, error, dt, G_Plane_Control.Elevator);
   end control_Pitch;



   procedure Compute_Target_Pitch is
   begin
      --  we cannot afford a (fail-safe) airspeed sensor, thus we rely on the polar:
      --  assuming that a certain pitch angle results in stable flight
      G_Target_Orientation.Pitch := Config.TARGET_PITCH;
      pragma Assert (G_Target_Orientation.Pitch < 0.0 * Degree); -- as long as this is constant, assert nose down
   end Compute_Target_Pitch;



   function Have_Home_Position return Boolean is
   begin
      return G_Target_Position.Longitude /= 0.0 * Degree and G_Target_Position.Latitude /= 0.0 * Degree;
   end Have_Home_Position;



   function Have_My_Position return Boolean is
   begin
      return G_Object_Position.Longitude /= 0.0 * Degree and G_Object_Position.Latitude /= 0.0 * Degree;
   end Have_My_Position;



   procedure Compute_Target_Roll is
      error : Angle_Type;
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type (Float ((now - G_Last_Yaw_Control) / Ada.Real_Time.Milliseconds(1)) * 1.0e-3);
      have_my_pos   : constant Boolean := Have_My_Position;
      have_home_pos : constant Boolean := Have_Home_Position;
   begin
      G_state.once_had_my_pos := G_state.once_had_my_pos or have_my_pos;

      if have_my_pos and then have_home_pos then
         --  compute relative location to target
         G_state.distance_to_target := Distance (G_Object_Position, G_Target_Position);
         G_Target_Orientation.Yaw := Yaw_Type (Bearing (G_Object_Position, G_Target_Position));

         if G_state.distance_to_target > Config.TARGET_AREA_RADIUS then
            --  some distance towards target => compute bearing and deduce roll

            --  PID controller to turn relative bearing to roll angle
            error := delta_Angle (G_Object_Orientation.Yaw, G_Target_Orientation.Yaw);
            Yaw_PID_Controller.step (PID_Yaw, error, dt, G_Target_Orientation.Roll);
            G_Last_Yaw_Control := now;
         else
            --  close to target => hold position
            G_Target_Orientation.Roll := Config.CIRCLE_TRAJECTORY_ROLL;
         end if;

      elsif have_home_pos and then (not have_my_pos and G_state.once_had_my_pos) then
         --  temporarily don't have my position => keep old bearing
         null;
      else
         pragma Assert (not have_home_pos or not G_state.once_had_my_pos);
         --  don't know where to go => hold position (circle other way around)
         G_Target_Orientation.Roll := -Config.CIRCLE_TRAJECTORY_ROLL;
      end if;
   end Compute_Target_Roll;



   function Elevon_Angles( elevator : Elevator_Angle_Type; aileron : Aileron_Angle_Type;
                           priority : Control_Priority_Type ) return Elevon_Angle_Array is
      balance : Float range 0.0 .. 2.0 := 1.0;
      scale : Float range 0.0 .. 1.0 := 1.0;
      balanced_elevator : Elevator_Angle_Type;
      balanced_aileron  : Aileron_Angle_Type;

   begin
      -- dynamic sharing of rudder angles between elevator and ailerons
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


   procedure Limit_Target_Attitude is
      function Sat_Pitch is new Saturate (Pitch_Type);
      function Sat_Roll is new Saturate (Roll_Type);
   begin
      G_Target_Orientation.Roll := Sat_Roll (val => G_Target_Orientation.Roll, min => -Config.MAX_ROLL, max => Config.MAX_ROLL);
      G_Target_Orientation.Pitch := Sat_Pitch (val => G_Target_Orientation.Pitch, min => -Config.MAX_PITCH, max => Config.MAX_PITCH);
   end Limit_Target_Attitude;


   procedure runOneCycle is
      Control_Priority : Control_Priority_Type := EQUAL;
   begin

      if not Config.Software.TEST_MODE_ACTIVE then
         --  the actual flight controller

         Compute_Target_Pitch;
         Compute_Target_Roll;

         --  TEST: overwrite roll with a fixed value
         G_Target_Orientation.Roll := Config.CIRCLE_TRAJECTORY_ROLL;  -- TEST: Omakurve

         --  evelope protection
         Limit_Target_Attitude;

         control_Pitch;
         control_Roll;
      else
         --  fake rudder waving for ground tests
         G_Plane_Control.Elevator := Elevator_Angle_Type (0.0);
         declare
            now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
            t_abs : constant Time_Type := Units.To_Time (now);
            sinval : constant Unit_Type := Unit_Type (Ada.Numerics.Elementary_Functions.Sin (2.0 * Float (t_abs)));
            pragma Assume (sinval in -1.0 .. 1.0);
            FAKE_ROLL_MAGNITUDE : constant Angle_Type := 20.0 * Degree;
         begin
            G_Plane_Control.Aileron := FAKE_ROLL_MAGNITUDE * sinval;
         end;
      end if;

      G_state.control_profiler.start;

      -- mix
      if abs( G_Object_Orientation.Roll ) > CFG_CONTROLL_UNSTABLE_ROLL_THRESHOLD then
         Control_Priority := ROLL_FIRST;
      end if;
      if abs( G_Object_Orientation.Pitch ) > CFG_CONTROLL_UNSTABLE_PITCH_THRESHOLD then
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



   function get_Elevons return Elevon_Angle_Array is
   begin
      return G_Elevon_Angles;
   end get_Elevons;


end Controller;
