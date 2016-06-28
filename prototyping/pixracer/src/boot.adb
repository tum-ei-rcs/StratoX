with Main;

--  the entry point after POR

procedure boot is
--  pragma Priority (MAIN_TASK_PRIORITY);
--  Self_Test_Passed : Boolean;
begin

   Main.Initialize;
   Main.Run_Loop;

end boot;
