

with Units.Navigation; use Units.Navigation;
with Config;

with Units; use Units;


with Logger;
with Estimator;
with Controller;


package body Mission is

   G_state : Mission_State_Type := UNKNOWN;
   G_Home_Position : GPS_Loacation_Type := (Config.DEFAULT_LONGITUDE * Degree, 
                                            Config.DEFAULT_LATITUDE * Degree, 
                                            0.0 * Meter);

   G_body_info : Body_Type;
   
   procedure start_New_Mission is
   begin
      if G_state = UNKNOWN or G_state = WAITING_FOR_RESET then
         G_state := INITIALIZING;
      else
         Logger.log(Logger.WARN, "Mission running, cannot start new Mission!");
      end if;
   end start_New_Mission;

   procedure run_Mission is
   begin
      case (G_state) is
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
      G_state := Mission_State_Type'Succ(G_state);
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
      G_Home_Position := Estimator.get_Position;
      
   end wait_For_Release;

   procedure monitor_Ascend is
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
      
      Controller.set_Target_Position( G_Home_Position );
      next_State;
   end perform_Detach;

   procedure control_Descend is
   begin
      -- Estimator
      Estimator.update;

      G_body_info.orientation := Estimator.get_Orientation;

      -- Controller
      Controller.set_Current_Orientation (G_body_info.orientation);
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
