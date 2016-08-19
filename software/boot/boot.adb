with Main;
with Config.Tasking;
with Crash; -- must be here, to activate last_chance_handler
pragma Unreferenced (Crash); -- protect the "with" above

-- the entry point after POR

procedure boot is
   pragma Priority (Config.Tasking.TASK_PRIO_MAIN);
-- Self_Test_Passed : Boolean;
begin

   Main.initialize;

   -- ToDo: check last system state

   -- test_System;
   -- Main.perform_Self_Test;

   -- finally jump to main
   Main.run_Loop;

end boot;
