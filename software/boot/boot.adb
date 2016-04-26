
with Main;

-- the entry point after POR
procedure boot is
   --pragma Priority (MAIN_TASK_PRIORITY);
   -- Self_Test_Passed : Boolean;
begin

	Main.initialize;

	-- ToDo: check last system state

	-- test_System;

	Main.run_Loop;

end boot;
