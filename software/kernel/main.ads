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

   procedure Initialize;

   procedure Perform_Self_Test (passed : out Boolean);

   procedure Run_Loop;

end Main;
