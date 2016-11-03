with Generic_Unit;

package Mission with SPARK_Mode is
   package New_Unit is new Generic_Unit(Index_Type => Integer,
                                        Element_Type => Float);
   use New_Unit;

   -- the mission can only go forward
   type Mission_State_Type is (
      UNKNOWN,
      INITIALIZING,
      SELF_TESTING,
      ASCENDING);

   procedure run_Mission;
end Mission;
