
with PX4IO.Driver;
with Servo;
with Generic_PID_Controller;
with Logger;
with Profiler;
with Config.Software; use Config.Software;
--with Units.Numerics; use Units.Numerics;
with Ada.Numerics.Elementary_Functions;
with Bounded_Image; use Bounded_Image;
with Interfaces; use Interfaces;
with ULog;
with Types; use Types;


with Ada.Real_Time; use Ada.Real_Time;
pragma Elaborate_All(Ada.Real_Time);

with Helper;

package body Controller with SPARK_Mode is

   --------------------
   --  TYPES
   --------------------

   type Logger_Call_Type is mod Config.Software.CFG_LOGGER_CALL_SKIP with Default_Value => 0;

   type Control_Mode_T is (MODE_UNKNOWN,
                           MODE_POSHOLD,  -- impossible to perform homing...holding position
                           MODE_HOMING, -- currently steering towards home
                           MODE_COURSEHOLD, -- temporarily lost navigation; hold last known course
                           MODE_ARRIVED); -- close enough to home

   type State_Type is record
      --  logging info
      logger_calls : Logger_Call_Type;
      logger_console_calls : Logger_Call_Type;
      control_profiler : Profiler.Profile_Tag;

      detach_animation_time : Time_Type := 0.0 * Second;

      --  homimg information:
      once_had_my_pos  : Boolean := False;
      distance_to_home : Length_Type := 0.0 * Meter;
      course_to_home   : Yaw_Type := 0.0 * Degree;
      controller_mode  : Control_Mode_T := MODE_UNKNOWN;
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
   G_Target_Orientation_Prev : Orientation_Type := G_Target_Orientation;


   G_state : State_Type;

   G_Last_Pitch_Control : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   G_Last_Roll_Control : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   G_Last_Yaw_Control : Ada.Real_Time.Time := Ada.Real_Time.Clock;


   G_Plane_Control : Plane_Control_Type := (others => 0.0 * Degree);
   G_Elevon_Angles : Elevon_Angle_Array := (others => 0.0 * Degree);

   --------------------
   --  PROTOTYPES
   --------------------

   procedure Limit_Target_Attitude with Inline,
     Global => (In_Out => (G_Target_Orientation));

   function Have_My_Position return Boolean with
     Global => (Input => G_Object_Position);

   function Have_Home_Position return Boolean with
     Global => (Input => G_Target_Position);

   procedure Update_Homing with
     Global => (Input => (G_Object_Position, G_Target_Position),
                In_Out => (G_state)),
     Depends => (G_state => (G_state, G_Object_Position, G_Target_Position));
   --  update distance and bearing to home coordinate, and decide what to do

   procedure Compute_Target_Attitude with
     Global => (Input => (G_state, G_Object_Orientation, Ada.Real_Time.Clock_Time),
                In_Out => (G_Last_Yaw_Control, PID_Yaw, G_Target_Orientation_Prev),
                Output => (G_Target_Orientation)),
--       Depends => (G_Last_Yaw_Control => (G_Last_Yaw_Control, G_state, Ada.Real_Time.Clock_Time),
--                   G_Target_Orientation => (G_state, PID_Yaw, G_Object_Orientation, G_Target_Orientation_Prev,
--                                            G_Last_Yaw_Control, Ada.Real_Time.Clock_Time),
--                   PID_Yaw => (PID_Yaw, G_Object_Orientation, G_Last_Yaw_Control, G_Target_Orientation_Prev,
--                               G_state, Ada.Real_Time.Clock_Time),
--                   G_Target_Orientation_Prev => (G_Target_Orientation_Prev, G_state, PID_Yaw,
--                                                 Ada.Real_Time.Clock_Time, G_Object_Orientation, G_Last_Yaw_Control)),
     Contract_Cases => ((G_state.controller_mode = MODE_COURSEHOLD) =>
                            G_Target_Orientation.Yaw = G_Target_Orientation_Prev.Yaw,
                        (G_state.controller_mode = MODE_HOMING) =>
                            G_Target_Orientation.Yaw = G_state.course_to_home,
                        (G_state.controller_mode not in MODE_HOMING | MODE_COURSEHOLD) =>
                            G_Target_Orientation.Yaw = G_Object_Orientation.Yaw,
                        others => True),
     Post => G_Target_Orientation_Prev = G_Target_Orientation;
   --  decide vehicle attitude depending on mode
   --  contract seems extensive, but it enforces that the attitude is always updated, and that
   --  homing works.


   ----------------
   --  initialize
   ----------------

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
      Logger.log_console(Logger.DEBUG, "Controller initialized");

   end initialize;

   --------------
   --  activate
   --------------

   procedure activate is
   begin
      Servo.activate;
   end activate;

   ----------------
   --  deactivate
   ----------------

   procedure deactivate is
   begin
      Servo.deactivate;
   end deactivate;

   --------------------------
   --  set_Current_Position
   --------------------------

   procedure set_Current_Position(location : GPS_Loacation_Type) is
   begin
      G_Object_Position := location;
   end set_Current_Position;

   -------------------------
   --  set_Target_Position
   -------------------------

   procedure set_Target_Position (location : GPS_Loacation_Type) is
   begin
      G_Target_Position := location;
      Logger.log (Logger.SENSOR, "Home=" & Integer_Img ( Integer (100000.0 * To_Degree (G_Target_Position.Latitude)))
                  & ", " & Integer_Img ( Integer (100000.0 * To_Degree (G_Target_Position.Longitude)))
                  & ", " & Integer_Img ( Sat_Cast_Int ( Float (G_Target_Position.Altitude))));
   end set_Target_Position;

   -----------------------------
   --  set_Current_Orientation
   -----------------------------

   procedure set_Current_Orientation (orientation : Orientation_Type) is
   begin
      G_Object_Orientation := orientation;
   end set_Current_Orientation;

   --------------
   --  log_Info
   --------------

   procedure log_Info is
      controller_msg : ULog.Message (Typ => ULog.CONTROLLER);
      nav_msg : ULog.Message (Typ => ULog.NAV);
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;

      function Sat_Sub_Alt is new Saturated_Subtraction (Altitude_Type);
   begin
      G_state.logger_console_calls := Logger_Call_Type'Succ( G_state.logger_console_calls );
      if G_state.logger_console_calls = 0 then
         Logger.log_console(Logger.DEBUG,
                            "Pos " & AImage( G_Object_Position.Longitude ) &
                              ", " & AImage( G_Object_Position.Latitude ) &
                              ", " & Image( G_Object_Position.Altitude ) &
                              ", d=" & Integer_Img (Sat_Cast_Int ( Float (G_state.distance_to_home))) &
                              ", crs=" & AImage (G_state.course_to_home));

         Logger.log_console(Logger.DEBUG,
                            "TY: " & AImage( G_Target_Orientation.Yaw ) &
                            ", TR: " & AImage( G_Target_Orientation.Roll ) &
                            "   Elev: " & AImage( G_Elevon_Angles(LEFT) ) & ", " & AImage( G_Elevon_Angles(RIGHT) )
                           );
      end if;

      -- log to SD
      controller_msg := ( Typ => ULog.CONTROLLER,
                          t => now,
                          target_yaw => Float (G_Target_Orientation.Yaw),
                          target_roll => Float (G_Target_Orientation.Roll),
                          target_pitch => Float (G_Target_Orientation.Pitch),
                          elevon_left => Float (G_Elevon_Angles(LEFT)),
                          elevon_right => Float (G_Elevon_Angles(RIGHT)),
                          ctrl_mode => Unsigned_8 (Control_Mode_T'Pos (G_state.controller_mode)));
      nav_msg := ( Typ => ULog.NAV,
                   t=> now,
                   home_dist => Float (G_state.distance_to_home),
                   home_course => Float (G_state.course_to_home),
                   home_altdiff => Float (Sat_Sub_Alt (G_Object_Position.Altitude, G_Target_Position.Altitude)));
      Logger.log_sd (Logger.INFO, controller_msg);
      Logger.log_sd (Logger.SENSOR, nav_msg);

   end log_Info;

   --------------
   --  set_hold
   --------------

   procedure set_hold is
   begin
      --  hold glider in position
      Servo.Set_Critical_Angle (Servo.LEFT_ELEVON, 38.0 * Degree );
      Servo.Set_Critical_Angle (Servo.RIGHT_ELEVON, 38.0 * Degree );
   end set_hold;

   ----------------
   --  set_detach
   ----------------

   procedure set_detach is
   begin
      Servo.Set_Critical_Angle (Servo.LEFT_ELEVON, -40.0 * Degree );
      Servo.Set_Critical_Angle (Servo.RIGHT_ELEVON, -40.0 * Degree );
   end set_detach;

   ----------
   --  sync
   ----------

   procedure sync is
   begin
      PX4IO.Driver.sync_Outputs;
   end sync;

   ----------
   --  bark
   ----------

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

   ------------------
   --  control_Roll
   ------------------

   procedure control_Roll is
      error : constant Angle_Type := (G_Target_Orientation.Roll - G_Object_Orientation.Roll);
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type (Float((now - G_Last_Roll_Control) / Ada.Real_Time.Milliseconds(1)) * 1.0e-3);
   begin
      G_Last_Roll_Control := now;
      Roll_PID_Controller.step (PID_Roll, error, dt, G_Plane_Control.Aileron);
   end control_Roll;

   -------------------
   --  control_Pitch
   -------------------

   procedure control_Pitch is
      error : constant Angle_Type := (G_Target_Orientation.Pitch - G_Object_Orientation.Pitch);
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type (Float((now - G_Last_Pitch_Control) / Ada.Real_Time.Milliseconds(1)) * 1.0e-3);
   begin
      G_Last_Pitch_Control := now;
      Pitch_PID_Controller.step (PID_Pitch, error, dt, G_Plane_Control.Elevator);
   end control_Pitch;

   ------------------------
   --  Have_Home_Position
   ------------------------

   function Have_Home_Position return Boolean is
   begin
      return G_Target_Position.Longitude /= 0.0 * Degree and G_Target_Position.Latitude /= 0.0 * Degree;
   end Have_Home_Position;

   ----------------------
   --  Have_My_Position
   ----------------------

   function Have_My_Position return Boolean is
   begin
      return G_Object_Position.Longitude /= 0.0 * Degree and G_Object_Position.Latitude /= 0.0 * Degree;
   end Have_My_Position;

   -------------------
   --  Update_Homing
   -------------------

   procedure Update_Homing is
      have_my_pos   : constant Boolean := Have_My_Position;
      have_home_pos : constant Boolean := Have_Home_Position;
   begin
      G_state.once_had_my_pos := G_state.once_had_my_pos or have_my_pos;

      if have_my_pos and then have_home_pos then
         --  compute relative location to target
         G_state.distance_to_home := Distance (G_Object_Position, G_Target_Position);
         G_state.course_to_home := Yaw_Type (Bearing (G_Object_Position, G_Target_Position));

         --  pos hold or homing, depending on distance
         if G_state.distance_to_home < Config.TARGET_AREA_RADIUS then
            --  we are at home
            G_state.controller_mode := MODE_ARRIVED;
         else
            --  some distance to target
            if G_state.controller_mode = MODE_ARRIVED then
               --  hysteresis if we already had arrived
               if G_state.distance_to_home > 2.0*Config.TARGET_AREA_RADIUS then
                  G_state.controller_mode := MODE_HOMING;
               else
                  G_state.controller_mode := MODE_ARRIVED;
               end if;
            else
               --  otherwise immediate homing
               G_state.controller_mode := MODE_HOMING;
            end if;
         end if;

      elsif have_home_pos and then (not have_my_pos and G_state.once_had_my_pos) then
         --  temporarily don't have my position => keep old bearing
         G_state.controller_mode := MODE_COURSEHOLD;

      else

         pragma Assert (not have_home_pos or not G_state.once_had_my_pos);
         --  don't know where to go => hold position
         G_state.controller_mode := MODE_POSHOLD;
      end if;

   end Update_Homing;

   -----------------------------
   --  Compute_Target_Attitude
   -----------------------------

   procedure Compute_Target_Attitude is
      error : Angle_Type;
      now   : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      dt    : constant Time_Type := Time_Type (Float ((now - G_Last_Yaw_Control) / Ada.Real_Time.Milliseconds(1)) * 1.0e-3);

   begin
      ------------
      --  Pitch
      ------------

      --  we cannot afford a (fail-safe) airspeed sensor, thus we rely on the polar:
      --  assuming that a certain pitch angle results in stable flight
      G_Target_Orientation.Pitch := Config.TARGET_PITCH;
      pragma Assert (G_Target_Orientation.Pitch < 0.0 * Degree); -- as long as this is constant, assert nose down

      ---------------
      --  Roll, Yaw
      ---------------

      case G_state.controller_mode is
         when MODE_UNKNOWN | MODE_POSHOLD =>
            --  circle left when we have no target
            G_Target_Orientation.Roll := -Config.CIRCLE_TRAJECTORY_ROLL;
            G_Target_Orientation.Yaw := G_Object_Orientation.Yaw;

         when MODE_HOMING | MODE_COURSEHOLD =>
            --  control yaw by setting roll
            if G_state.controller_mode = MODE_HOMING then
               G_Target_Orientation.Yaw := G_state.course_to_home;
            else
               G_Target_Orientation.Yaw := G_Target_Orientation_Prev.Yaw;
            end if;
            error := delta_Angle (G_Object_Orientation.Yaw, G_Target_Orientation.Yaw);
            Yaw_PID_Controller.step (PID_Yaw, error, dt, G_Target_Orientation.Roll);
            G_Last_Yaw_Control := now;

         when MODE_ARRIVED =>
            --  circle right when we are there
            G_Target_Orientation.Roll := Config.CIRCLE_TRAJECTORY_ROLL;
            G_Target_Orientation.Yaw := G_Object_Orientation.Yaw;

      end case;
      G_Target_Orientation_Prev := G_Target_Orientation;

   end Compute_Target_Attitude;

   ------------------
   --  Elevon_Angles
   ------------------

   function Elevon_Angles( elevator : Elevator_Angle_Type; aileron : Aileron_Angle_Type;
                           priority : Control_Priority_Type ) return Elevon_Angle_Array is
      balance : Float range 0.0 .. 2.0;-- := 1.0;
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

   ---------------------------
   --  Limit_Target_Attitude
   ---------------------------

   procedure Limit_Target_Attitude is
      function Sat_Pitch is new Saturate (Pitch_Type);
      function Sat_Roll is new Saturate (Roll_Type);
   begin
      G_Target_Orientation.Roll := Sat_Roll (val => G_Target_Orientation.Roll, min => -Config.MAX_ROLL, max => Config.MAX_ROLL);
      G_Target_Orientation.Pitch := Sat_Pitch (val => G_Target_Orientation.Pitch, min => -Config.MAX_PITCH, max => Config.MAX_PITCH);
   end Limit_Target_Attitude;

   -----------------
   --  runOneCycle
   -----------------

   procedure runOneCycle is
      Control_Priority : Control_Priority_Type := EQUAL;
      oldmode : constant Control_Mode_T := G_state.controller_mode;
   begin

      Update_Homing;

      if G_state.controller_mode /= oldmode then
         Logger.log_console (Logger.DEBUG, "Homing mode=" & Unsigned8_Img (Control_Mode_T'Pos (G_state.controller_mode)));
      end if;

      Compute_Target_Attitude;

      --  TEST: overwrite roll with a fixed value
      -- G_Target_Orientation.Roll := Config.CIRCLE_TRAJECTORY_ROLL;  -- TEST: Omakurve

      --  evelope protection
      Limit_Target_Attitude;

      --  compute elevon position
      if not Config.Software.TEST_MODE_ACTIVE then
         control_Pitch;
         control_Roll;

      else
         --  fake elevon waving for ground tests
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

   ----------------
   --  get_Elevons
   ----------------

   function get_Elevons return Elevon_Angle_Array is
   begin
      return G_Elevon_Angles;
   end get_Elevons;


end Controller;
