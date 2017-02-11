with Main;
with Config.Tasking;
with Crash; -- must be here, to activate last_chance_handler
with LED_Manager;
pragma Unreferenced (Crash); -- protect the "with" above

-- the entry point after POR

procedure boot with SPARK_Mode is
   pragma Priority (Config.Tasking.TASK_PRIO_MAIN);
   Self_Test_Passed : Boolean := False;
begin

   Main.Initialize;

   -- self-checks, unless in air reset
   LED_Manager.LED_switchOn;
   Main.Perform_Self_Test (Self_Test_Passed);

   -- finally jump to main, if checks passed
   if Self_Test_Passed then
      Main.Run_Loop;
   else
      LED_Manager.LED_switchOff;
      loop
         null;
      end loop;
   end if;

end boot;
