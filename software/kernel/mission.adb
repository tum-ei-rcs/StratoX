
with Logger;

package body Mission is

   state : Mission_State_Type := UNKNOWN;

   procedure start_New_Mission is
   begin
      null;
   end start_New_Mission;

   procedure run_Mission is
   begin
      case (state) is
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
            
   end run_Mission;

private
   
   procedure perform_Initialization is
   begin
      null;
   end perform_Initialization;

   procedure perform_Self_Test is
   begin
      null;
   end perform_Self_Test;

   procedure wait_For_Arm is
   begin
      null;
   end wait_For_Arm;

   procedure wait_For_Release is
   begin
      null;
   end wait_For_Release;

   procedure monitor_Ascend is
   begin
      null;
   end monitor_Ascend;
   
   procedure perform_Detach is
   begin
      null;
   end perform_Detach;

   procedure control_Descend is
   begin
      null;
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
