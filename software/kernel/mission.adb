
with Ada.Real_Time; use Ada.Real_Time;

with Units.Navigation; use Units.Navigation;
with Config;
with HIL;

with Units; use Units;


with Logger;
with Estimator;
with Controller;
with NVRAM; use NVRAM;


package body Mission is

   type State_Type is record 
      mission_state  : Mission_State_Type := UNKNOWN;
      mission_event  : Mission_Event_Type := NONE;
      last_call_time : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      threshold_time : Time_Type := 0.0 * Second;
      home           : GPS_Loacation_Type := (Config.DEFAULT_LONGITUDE * Degree, 
                                             Config.DEFAULT_LATITUDE * Degree, 
                                             0.0 * Meter);
      body_info     : Body_Type;
      last_call     : Ada.Real_Time.Time;
      last_state_change : Ada.Real_Time.Time;
   end record;

   G_state : State_Type;
   
   procedure start_New_Mission is
   begin
      if G_state.mission_state = UNKNOWN or G_state.mission_state = WAITING_FOR_RESET then
         G_state.mission_state := INITIALIZING;
         Logger.log(Logger.INFO, "New Mission.");
      else
         Logger.log(Logger.WARN, "Mission running, cannot start new Mission!");
      end if;
   end start_New_Mission;
   
   procedure load_Mission is
      old_state_val : HIL.Byte := HIL.Byte( 0 );
   begin
      NVRAM.Load( VAR_MISSIONSTATE, old_state_val );
      G_state.mission_state := Mission_State_Type'Val( old_state_val );
      if G_state.mission_state = UNKNOWN then
         start_New_Mission;
      else
         Estimator.initialize;
         Controller.initialize;
      end if;
      Logger.log(Logger.INFO, "Continue Mission at " & Integer'Image( Mission_State_Type'Pos( G_state.mission_state ) ) );
   end load_Mission;

   procedure run_Mission is
   begin
      case (G_state.mission_state) is
         when UNKNOWN => null;
         when INITIALIZING => 
            perform_Initialization;
            
         when SELF_TESTING =>
            perform_Self_Test;
            
         when WAITING_FOR_ARM =>
            wait_For_Arm;
            
         when WAITING_FOR_RELEASE =>
            wait_For_Release;
            
         when ASCENDING =>
            monitor_Ascend;
            
         when DETACHING =>
            perform_Detach;
            
         when DESCENDING =>
            control_Descend;
         
         when WAITING_ON_GROUND =>
            wait_On_Ground;
            
         --when WAITING_FOR_EVALUATION =>
         --   wait_
         when WAITING_FOR_RESET =>
            null;
            
      end case;
      
      G_state.last_call := Ada.Real_Time.Clock;
   end run_Mission;

   
   procedure next_State is
   begin
      G_state.mission_state := Mission_State_Type'Succ(G_state.mission_state);
      NVRAM.Store( VAR_MISSIONSTATE, Mission_State_Type'Pos( G_state.mission_state ) );
      G_state.last_state_change := Ada.Real_Time.Clock;
   end next_State;
   
   
   procedure perform_Initialization is
   begin
      G_state.last_state_change := Ada.Real_Time.Clock;
      G_state.body_info.orientation := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
      G_state.body_info.position := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);
   
      -- Estimator.initialize;
      -- Controller.initialize;
      Logger.log(Logger.INFO, "Mission Initialized");
      next_State;
   end perform_Initialization;

   procedure perform_Self_Test is
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
   
      -- get initial values
      Estimator.update;
   

      -- check GPS lock
      if Estimator.get_GPS_Fix = FIX_3D then
         G_state.home := Estimator.get_Position;
         Logger.log(Logger.INFO, "Mission Ready");
         next_State;
      end if;

      -- FOR TEST
      if now > G_state.last_state_change + Ada.Real_Time.Milliseconds( 500 ) then
         next_State;
      end if;
      
   end perform_Self_Test;

   procedure wait_For_Arm is
   begin
      Estimator.update;
      next_State;
   end wait_For_Arm;

   procedure wait_For_Release is
   begin
      Logger.log(Logger.INFO, "Start Ascending");
      next_State;
   end wait_For_Release;

   procedure monitor_Ascend is
      height : Altitude_Type := 0.0 * Meter;
   begin
      -- Estimator
      Estimator.update;
     
     
      -- check target height
      if Estimator.get_current_Height >= G_state.home.Altitude + Config.CFG_TARGET_ALTITUDE_THRESHOLD then
         G_state.threshold_time := G_state.threshold_time + 10.0 * Milli*Second;  -- TODO: calc dT     
         if G_state.threshold_time >= Config.CFG_TARGET_ALTITUDE_THRESHOLD_TIME then
            Logger.log(Logger.INFO, "Target height reached. Detaching...");
            next_State;
         end if;
      else
         G_state.threshold_time := 0.0 * Second;
      end if;
      
      -- check for accidential drop
      if Estimator.get_current_Height < Estimator.get_max_Height - Config.CFG_DELTA_ALTITUDE_THRESH then
         G_state.threshold_time := G_state.threshold_time + 10.0 * Milli*Second;  -- TODO: calc dT
         if G_state.threshold_time >= Config.CFG_DELTA_ALTITUDE_THRESH_TIME then
            Logger.log(Logger.INFO, "Unplanned drop detected...");
            next_State;         
         end if;
      else
         G_state.threshold_time := 0.0 * Second;  -- TODO: calc dT
      end if;
      
      
   end monitor_Ascend;
   
   procedure perform_Detach is
      isAttached : Boolean := True;
   begin
      Controller.activate;

      while isAttached loop
         Controller.detach;
         isAttached := False;
      end loop;
      
      Controller.set_Target_Position( G_state.home );
      Logger.log(Logger.INFO, "Detach successful, flying home");
      next_State;
   end perform_Detach;

   procedure control_Descend is
   begin
      -- Estimator
      Estimator.update;

      G_state.body_info.orientation := Estimator.get_Orientation;
      G_state.body_info.position := Estimator.get_Position;

      -- Controller
      Controller.set_Current_Orientation (G_state.body_info.orientation);
      Controller.set_Current_Position (G_state.body_info.position);
      Controller.runOneCycle; 
      
   end control_Descend;

   procedure wait_On_Ground is
   begin
      null;
   end wait_On_Ground;

   procedure perform_Evaluation is
   begin
      null;
   end perform_Evaluation;


end Mission;
