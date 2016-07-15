
with Ada.Real_Time; use Ada.Real_Time;

with Units.Navigation; use Units.Navigation;
with Config;
with HIL;

with Units; use Units;


with Console; use Console;
with Logger;
with Estimator;
with Controller;
with NVRAM; use NVRAM;


package body Mission is

   type State_Type is record 
      mission_state  : Mission_State_Type := UNKNOWN;
      mission_event  : Mission_Event_Type := NONE;
      last_call_time : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      delta_threshold_time : Time_Type := 0.0 * Second;
      target_threshold_time : Time_Type := 0.0 * Second;
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
      if G_state.mission_state = UNKNOWN or G_state.mission_state = WAITING_FOR_RESET then
         start_New_Mission;
      else
         -- Estimator.initialize;
         -- Controller.initialize;
         Logger.log(Logger.INFO, "Continue Mission at " & Integer'Image( Mission_State_Type'Pos( G_state.mission_state ) ) );
      end if;    
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
            
         when WAITING_FOR_RESET =>
            wait_For_Reset;
            
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
   
      -- set hold
      Controller.set_hold;

      -- check GPS lock
      if Estimator.get_GPS_Fix = FIX_3D then
         G_state.home := Estimator.get_Position;
         Logger.log(Logger.INFO, "Mission Ready");
         next_State;
      end if;

      -- FOR TEST
      if now > G_state.last_state_change + Ada.Real_Time.Seconds( 10 ) then
         G_state.home := Estimator.get_Position;
         G_state.home.Altitude := Estimator.get_current_Height;
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
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      -- Estimator
      Estimator.update;
     
     
      -- check target height
      if Estimator.get_current_Height >= G_state.home.Altitude + Config.CFG_TARGET_ALTITUDE_THRESHOLD then
         G_state.target_threshold_time := G_state.target_threshold_time + To_Time(now - G_state.last_call);  -- TODO: calc dT     
         if G_state.target_threshold_time >= Config.CFG_TARGET_ALTITUDE_THRESHOLD_TIME then
            Logger.log(Logger.INFO, "Target height reached. Detaching...");
            Logger.log(Logger.INFO, "Target height reached. Detaching...");
            next_State;
         end if;
      else
         G_state.target_threshold_time := 0.0 * Second;
      end if;
      
      -- check for accidential drop
      if Estimator.get_current_Height < Estimator.get_max_Height - Config.CFG_DELTA_ALTITUDE_THRESH then
         G_state.delta_threshold_time := G_state.delta_threshold_time + To_Time(now - G_state.last_call);  -- TODO: calc dT
         if G_state.delta_threshold_time >= Config.CFG_DELTA_ALTITUDE_THRESH_TIME then
            Logger.log(Logger.INFO, "Unplanned drop detected...");
            Logger.log(Logger.INFO, "Unplanned drop detected...");
            next_State;         
         end if;
      else
         G_state.delta_threshold_time := 0.0 * Second;  -- TODO: calc dT
      end if;
   
      -- Test 40 Sek descend
      if now > G_state.last_state_change + Seconds(120) then
         Logger.log(Logger.INFO, "Timeout Ascend");
         Logger.log(Logger.INFO, "Timeout Ascend");
         next_State;
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
      Estimator.reset_log_calls;     
      Logger.log(Logger.INFO, "Detached");
      next_State;
   end perform_Detach;

   procedure control_Descend is
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      -- Estimator
      Estimator.update;

      G_state.body_info.orientation := Estimator.get_Orientation;
      G_state.body_info.position := Estimator.get_Position;

      -- Controller
      Controller.set_Current_Orientation (G_state.body_info.orientation);
      Controller.set_Current_Position (G_state.body_info.position);
      Controller.runOneCycle; 
      
      
      -- Test 40 Sek descend
      if now > G_state.last_state_change + Seconds(120) then
         Logger.log(Logger.INFO, "Timeout. Landed");
         Controller.deactivate;
         next_State;
      end if;
      
      
   end control_Descend;

   procedure wait_On_Ground is
      command : Console.User_Command_Type;
   begin
      -- Console
      Console.read_Command( command );

      case ( command ) is
         when Console.DISARM =>
            Logger.log(Logger.INFO, "Mission Finished");
            next_State;
            
         when others =>
            null;
      end case;

   end wait_On_Ground;

   procedure wait_For_Reset is
   begin
      null;
   end wait_For_Reset;


end Mission;
