-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
-- Module: Main
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: The main program
--
-- ToDo:
-- [ ] Implementation

package Main with
   SPARK_Mode
is

   procedure initialize;

   procedure perform_Self_Test (passed : out Boolean);

   procedure run_Loop;

end Main;
