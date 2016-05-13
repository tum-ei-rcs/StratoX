
with Main;

-- the entry point after POR
procedure boot is
   --pragma Priority (MAIN_TASK_PRIORITY);
   -- Self_Test_Passed : Boolean;
begin

	Main.initialize;

	-- ToDo: check last system state

	-- test_System;
        Main.perform_Self_Test;

   -- finally jump to main
	Main.run_Loop;

end boot;
