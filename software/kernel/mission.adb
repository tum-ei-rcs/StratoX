

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
      mission_state : Mission_State_Type := UNKNOWN;
      mission_event : Mission_Event_Type := NONE;
      home          : GPS_Loacation_Type := (Config.DEFAULT_LONGITUDE * Degree, 
                                             Config.DEFAULT_LATITUDE * Degree, 
                                             0.0 * Meter);
      body_info     : Body_Type;
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
   end run_Mission;

   
   procedure next_State is
   begin
      G_state.mission_state := Mission_State_Type'Succ(G_state.mission_state);
      NVRAM.Store( VAR_MISSIONSTATE, Mission_State_Type'Pos( G_state.mission_state ) );
   end next_State;
         
   procedure perform_Initialization is
   begin
      Estimator.initialize;
      Controller.initialize;
      next_State;
   end perform_Initialization;

   procedure perform_Self_Test is
   begin
      next_State;
      -- check GPS lock
      
   end perform_Self_Test;

   procedure wait_For_Arm is
   begin
      next_State;
   end wait_For_Arm;

   procedure wait_For_Release is
   begin
      next_State;
      Estimator.update;
      G_state.home := Estimator.get_Position;
      
   end wait_For_Release;

   procedure monitor_Ascend is
      height : Altitude_Type := 0.0 * Meter;
   begin
      -- Estimator
      Estimator.update;
      
      
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
      next_State;
   end perform_Detach;

   procedure control_Descend is
   begin
      -- Estimator
      Estimator.update;

      G_state.body_info.orientation := Estimator.get_Orientation;

      -- Controller
      Controller.set_Current_Orientation (G_state.body_info.orientation);
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
