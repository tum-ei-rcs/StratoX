

package Mission with SPARK_Mode is

   -- the mission can only go forward
   type Mission_State_Type is (
      UNKNOWN,
      INITIALIZING,
      WAITING_FOR_GPS,
      STARTING,
      WAITING_FOR_ASCEND,
      ASCENDING,
      DETACHING,
      DESCENDING,
      WAITING_ON_GROUND,
      WAITING_FOR_RESET
   );

   type Mission_Event_Type is (
      NONE,
      INITIALIZED,
      SELF_TEST_OK,
      ARMED,
      RELEASED,
      BALLOON_DETACHED,
      LANDED,
      FOUND,
      EVALUATED
   );

   procedure start_New_Mission;
   
   procedure load_Mission;

   procedure run_Mission;
   
   function Is_Resumed return Boolean;
   
   function get_state return Mission_State_Type;

private
   
   procedure perform_Initialization;

   procedure wait_for_GPSfix;

   procedure perform_Start; -- screws with timing
   
   procedure wait_For_Ascend;

   procedure monitor_Ascend with Pre => True; -- workaround got GNATprove bug P811-036
   
   procedure perform_Detach; -- screws with timing   

   procedure control_Descend;

   procedure wait_On_Ground;

   procedure wait_For_Reset;

end Mission;
