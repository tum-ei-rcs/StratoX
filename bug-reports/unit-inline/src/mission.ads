
package Mission with SPARK_Mode is

   -- the mission can only go forward
   type Mission_State_Type is (
      UNKNOWN,
      INITIALIZING,
      SELF_TESTING,
      ASCENDING);

   procedure run_Mission;
end Mission;
