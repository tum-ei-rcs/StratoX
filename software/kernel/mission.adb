
with Ada.Real_Time; use Ada.Real_Time;

with Units.Navigation; use Units.Navigation;
with Config.Software;
with HIL;
with Types; use Types;

with Units; use Units;
with Bounded_Image; use Bounded_Image;

with Console; use Console;
with Buzzer_Manager;
with Logger;
--  with ULog;

with Estimator;
with Controller;
with NVRAM; use NVRAM;
with Interfaces; use Interfaces;


package body Mission with SPARK_Mode is

   type State_Type is record 
      mission_state  : Mission_State_Type := UNKNOWN;
      mission_event  : Mission_Event_Type := NONE;
      last_call_time : Ada.Real_Time.Time := Ada.Real_Time.Time_First; -- time of last state machine call
      gps_lock_threshold_time : Time_Type := 0.0 * Second; -- time since last acquisition of GPS lick
      landed_wait_time : Time_Type := 0.0 * Second; -- time since touchdown
      dropping_time : Time_Type := 0.0 * Second; -- acc. time of dropping
      target_altitude_time : Time_Type := 0.0 * Second; -- acc. time since target altitude was reached
      home           : GPS_Loacation_Type := (Config.DEFAULT_HOME_LONG, 
                                             Config.DEFAULT_HOME_LAT, 
                                             Config.DEFAULT_HOME_ALT_MSL);
      body_info     : Body_Type;
      last_call     : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
      last_state_change : Ada.Real_Time.Time := Ada.Real_Time.Time_First; -- time of last transition in state machine
   end record;

   --------------
   --  Helpers
   --------------
   
   function Sat_Add_Time is new Saturated_Addition (Time_Type);
   
   -----------
   --  Specs
   -----------
   
   procedure Enter_State (state : Mission_State_Type);
   
   -------------
   --  states
   -------------
   
   G_state : State_Type;
   
   Mission_Resumed : Boolean := False;
   

   -----------------
   --  subprograms
   -----------------
   
     
   function New_Mission_Enabled return Boolean is 
     (G_state.mission_state = UNKNOWN or G_state.mission_state = WAITING_FOR_RESET);
  
   
   
   function Is_Resumed return Boolean is (Mission_Resumed);
   
   
   
   procedure start_New_Mission is
   begin
      if New_Mission_Enabled then
         NVRAM.Reset;
         G_state.mission_state := INITIALIZING;
         Logger.log(Logger.INFO, "New Mission.");         
      else
         Logger.log(Logger.WARN, "Mission running, cannot start new Mission!");
      end if;
   end start_New_Mission;
   
   
   
   procedure load_Mission is
      old_state_val : HIL.Byte;
      height : HIL.Byte_Array_2;
      baro_height : Altitude_Type;
      
      function Sat_Cast_Alt is new Saturated_Cast (Altitude_Type);
      
   begin
      NVRAM.Load( VAR_MISSIONSTATE, old_state_val );
      if old_state_val <= Mission_State_Type'Pos (Mission_State_Type'Last) then
         G_state.mission_state := Mission_State_Type'Val (old_state_val);
      else
         G_state.mission_state := Mission_State_Type'First;
      end if;
      if G_state.mission_state = UNKNOWN or G_state.mission_state = WAITING_FOR_RESET then
         --  new mission
         start_New_Mission;
         Mission_Resumed := False;
                  
      else
         --  resume after reset: load values
         --  Baro
         NVRAM.Load( VAR_HOME_HEIGHT_L, height(1) );
         pragma Annotate (GNATprove, False_Positive, """height"" might not be initialized", "it is done right here");
         NVRAM.Load( VAR_HOME_HEIGHT_H, height(2) );
         baro_height := Sat_Cast_Alt (Float (Unit_Type (HIL.toUnsigned_16 (height)) * Meter));
         
         --  GPS
         NVRAM.Load( VAR_GPS_TARGET_LONG_A, Float( G_state.home.Longitude ) );
         NVRAM.Load( VAR_GPS_TARGET_LAT_A,  Float( G_state.home.Latitude ) );
         NVRAM.Load( VAR_GPS_TARGET_ALT_A,  Float( G_state.home.Altitude ) );
         
         --  re-lock Home
         Logger.log(Logger.DEBUG, "Home Alt: " & Image(G_state.home.Altitude) );  
         Estimator.lock_Home( G_state.home, baro_height );
         Controller.set_Target_Position( G_state.home );
         
         Logger.log(Logger.INFO, "Continue Mission at " & Integer_Img (Mission_State_Type'Pos (G_state.mission_state)));
         Mission_Resumed := True;
         
         -- beep thrice to indicate mission is continued (overwritten in case the state entry wants otherwise)
         Buzzer_Manager.Beep (f => 2000.0*Hertz, Reps => 3, Period => 0.5*Second, Length => 0.2*Second);         
      end if;    
      
      Enter_State (G_state.mission_state);
   end load_Mission;


   
   procedure handle_Event( event : Mission_Event_Type ) is
   begin
      null;
   end handle_Event;
   pragma Unreferenced (handle_Event);
   
   
      
   procedure next_State is
   begin
      if G_state.mission_state /= Mission_State_Type'Last then
         G_state.mission_state := Mission_State_Type'Succ(G_state.mission_state);
         NVRAM.Store( VAR_MISSIONSTATE, HIL.Byte (Mission_State_Type'Pos (G_state.mission_state)));
         Enter_State (G_state.mission_state);
      end if;
   end next_State;
   
   
   
   procedure perform_Initialization is
   begin
      G_state.last_state_change := Ada.Real_Time.Clock;
      G_state.body_info.orientation := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
      G_state.body_info.position := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);
   
      -- set hold
      -- Controller.set_hold;
      
      Logger.log(Logger.INFO, "Mission Initialized");
      next_State;
   end perform_Initialization;

   
   
   procedure wait_for_GPSfix is
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
                  
      procedure lock_Home is
      begin
         G_state.home := Estimator.get_Position;
         Estimator.lock_Home (Estimator.get_Position, Estimator.get_Baro_Height);
         --G_state.home.Altitude := Estimator.get_current_Height;
         declare
            alt_u16 : constant Unsigned_16 := Sat_Cast_U16 (Float (Estimator.get_Baro_Height));
         begin
            NVRAM.Store (VAR_HOME_HEIGHT_L, HIL.toBytes (alt_u16)(1));
            NVRAM.Store (VAR_HOME_HEIGHT_H, HIL.toBytes (alt_u16)(2));
         end;
         
         NVRAM.Store (VAR_GPS_TARGET_LONG_A, Float (G_state.home.Longitude));
         NVRAM.Store (VAR_GPS_TARGET_LAT_A,  Float (G_state.home.Latitude));
         NVRAM.Store (VAR_GPS_TARGET_ALT_A,  Float (G_state.home.Altitude));
         Controller.set_Target_Position (G_state.home);
                                    
      end lock_Home;     
      
   begin
   
      -- get initial values
      Estimator.update( (0.0*Degree, 0.0*Degree) );
      
      -- set hold
      Controller.set_hold;
      Controller.sync;

      -- check duration of GPS lock
      if Estimator.get_GPS_Fix = FIX_3D and then 
        Estimator.get_Pos_Accuracy < Config.Software.POSITION_LEAST_ACCURACY 
      then
                
         G_state.gps_lock_threshold_time := Sat_Add_Time (G_state.gps_lock_threshold_time, To_Time (now - G_state.last_call));
--         LED_Manager.LED_switchOn;
         
         if G_state.gps_lock_threshold_time > 60.0 * Second then
            lock_Home;
            Logger.log(Logger.INFO, "Mission Ready");
            next_State;
         end if;
      else
         G_state.gps_lock_threshold_time := 0.0 * Second;
      end if;

      -- FOR TEST ONLY: skip to next state after a timeout
      if Config.Software.TEST_MODE_ACTIVE and then
        now > G_state.last_state_change + Config.Software.CFG_GPS_LOCK_TIMEOUT 
      then
         lock_Home;
         next_State;
      end if;
      
   end wait_for_GPSfix;

   
   
   procedure perform_Start is
   begin
      Estimator.update ((0.0*Degree, 0.0*Degree));
      Controller.bark;
      next_State;
   end perform_Start;

   
   
   procedure wait_For_Ascend is
   begin
      -- TODO: ascend detection
      Logger.log(Logger.INFO, "Start Ascending");
      next_State;
   end wait_For_Ascend;

   
   
   procedure monitor_Ascend is
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      --  Estimator
      Estimator.update ((0.0*Degree, 0.0*Degree));
     
      --  set hold
      Controller.set_hold; 
      Controller.sync;
  
      --  check target altitude
      --  FIXME: Sprung von Baro auf GPS hat ausgeloest.
      if Estimator.get_relative_Height >= Config.CFG_TARGET_ALTITUDE then
         G_state.target_altitude_time := Sat_Add_Time (G_state.target_altitude_time, 
                                                        To_Time(now - G_state.last_call));  -- TODO: calc dT     
         if G_state.target_altitude_time >= Config.CFG_TARGET_ALTITUDE_TIME then
            Logger.log(Logger.INFO, "Target alt reached");
            next_State;
         end if;
      else
         G_state.target_altitude_time := 0.0 * Second;
      end if;
      
      --  check for accidential drop
      if Estimator.get_current_Height < Estimator.get_max_Height - Config.CFG_DELTA_ALTITUDE_THRESH then
         G_state.dropping_time := Sat_Add_Time (G_state.dropping_time, To_Time(now - G_state.last_call));  -- TODO: calc dT
         if G_state.dropping_time >= Config.CFG_DELTA_ALTITUDE_THRESH_TIME then
            Logger.log(Logger.INFO, "Unplanned drop detected");
            next_State;         
         end if;
      else
         G_state.dropping_time := 0.0 * Second;  -- TODO: calc dT
      end if;
   
      --  Check Timeout
      if now > G_state.last_state_change + Units.To_Time_Span( Config.Software.CFG_ASCEND_TIMEOUT ) then   -- 600
         Logger.log(Logger.INFO, "Timeout Ascend");
         next_State;
      end if;
      
   end monitor_Ascend;
   
   
   
   function get_state return Mission_State_Type is (G_state.mission_state);
   
   
   procedure perform_Detach is
      isAttached : Boolean := True;
      start : Ada.Real_Time.Time;
   begin
      Controller.activate;

      while isAttached loop
         Controller.set_detach;
         for k in Integer range 1 .. 40 loop
            start := Ada.Real_Time.Clock;
            Estimator.update( (0.0*Degree, 0.0*Degree) );
            Controller.sync;
            delay until start + Milliseconds(20);
         end loop;
         Controller.set_hold;
         for k in Integer range 1 .. 15 loop
            start := Ada.Real_Time.Clock;
            Estimator.update( (0.0*Degree, 0.0*Degree) );
            Controller.sync;
            delay until start + Milliseconds(20);
         end loop;
         Controller.set_detach;
         for k in Integer range 1 .. 30 loop
            start := Ada.Real_Time.Clock;
            Estimator.update( (0.0*Degree, 0.0*Degree) );
            Controller.sync;
            delay until start + Milliseconds(20);
         end loop;
         
         --  FIXME: "attached" detection
         isAttached := False;
      end loop;
      
      Estimator.reset_log_calls;    
      Estimator.reset;
      
      Logger.log(Logger.INFO, "Detached");
      next_State;
   end perform_Detach;

   
   procedure Enter_State (state : Mission_State_Type) is 
   begin
      case state is 
         when INITIALIZING =>
            --  beep once to indicate fresh mission starts now
            Buzzer_Manager.Beep (f => 2000.0*Hertz, Reps => 2, Period => 1.5*Second, Length => 0.2*Second);
            
         when STARTING =>
            --  beep long once to indiate mission starts now
            Buzzer_Manager.Beep (f => 1000.0*Hertz, Reps => 1, Period => 2.0*Second, Length => 1.0*Second);
            
         when WAITING_FOR_RESET | WAITING_ON_GROUND =>
            --  beep infinitly to make someone pick me up
            Buzzer_Manager.Beep (f => 1000.0*Hertz, Reps => 0, Period => 4.0*Second, Length => 0.5*Second);
                        
         when others =>
            null;
      end case;
      G_state.last_state_change := Ada.Real_Time.Clock;
   end Enter_State;
   
   procedure control_Descend is
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      
      procedure deactivate is
      begin
         Controller.deactivate;
         next_State;  
         --  beep forever; once every 4 seconds
      end deactivate;
      
      Elevons : constant Controller.Elevon_Angle_Array := Controller.get_Elevons;
   begin
      -- Estimator
      Estimator.update( (Elevons(Controller.RIGHT)/2.0 + Elevons(Controller.LEFT)/2.0,
                         Elevons(Controller.RIGHT)/2.0 - Elevons(Controller.LEFT)/2.0) );
      
      G_state.body_info.orientation := Estimator.get_Orientation;
      G_state.body_info.position    := Estimator.get_Position;

      --  Controller
      Controller.set_Current_Orientation (G_state.body_info.orientation);
      Controller.set_Current_Position (G_state.body_info.position);
      Controller.runOneCycle;       
            
      --  Land detection (not in test mode) or timeout
      if not Config.Software.TEST_MODE_ACTIVE and 
      then now > (G_state.last_state_change + Config.Software.CFG_LANDED_STABLE_TIME) and
      then Estimator.get_Stable_Time > Config.Software.CFG_LANDED_STABLE_TIME
      then
         --  stable position (unchanged for 2 min)
         Logger.log(Logger.INFO, "Landed.");
         deactivate;
         
      elsif now > (G_state.last_state_change + Config.Software.CFG_DESCEND_TIMEOUT) then
         --  Timeout for Landing
         Logger.log(Logger.INFO, "Timeout. Landed");
         deactivate;
      end if;      
      
   end control_Descend;

   
   
   procedure wait_On_Ground is
      now : constant Ada.Real_Time.Time := Clock;
   begin
      --  Estimator
      Estimator.update ((0.0*Degree, 0.0*Degree));
      
      -- stay here for a while to log the landing location away
      G_state.landed_wait_time := Sat_Add_Time (G_state.landed_wait_time, To_Time (now - G_state.last_call));
      
      if G_state.landed_wait_time > 60.0 * Second then
         Logger.log(Logger.INFO, "Mission Finished");
         --  beep once to indicate fresh mission starts now
         next_State;
         -- FIXME: turn everything OFF to save power
      end if;
         
   end wait_On_Ground;

   
   
   procedure wait_For_Reset is
   begin
      null;
   end wait_For_Reset;

      

   procedure run_Mission is
      this_task_begin : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      --  this *MUST* be taken before executing the code below,
      --  otherwise the code below will measure the difference between
      --  loop budget and time taken by itself...which is of course
      --  shorter than the loop rate.
   begin
      
      case (G_state.mission_state) is
         when UNKNOWN => null;
         when INITIALIZING => 
            perform_Initialization;
            
         when WAITING_FOR_GPS =>
            wait_for_GPSfix;
            
         when STARTING =>
            perform_Start;
            
         when WAITING_FOR_ASCEND =>
            wait_For_Ascend;
            
         when ASCENDING =>
            monitor_Ascend;               
            
         when DETACHING =>
            perform_Detach;
            
         when DESCENDING =>
            control_Descend;
         
         when WAITING_ON_GROUND =>
            wait_On_Ground;
            
         when WAITING_FOR_RESET =>
            wait_For_Reset;
            
      end case;
      G_state.last_call := this_task_begin;
   end run_Mission;

end Mission;
