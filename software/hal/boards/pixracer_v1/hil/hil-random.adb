--  Institution: Technische Universität München
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker
with STM32.RNG.Polling;

--  @summary
--  Target-independent specification for HIL of Random number generator
package body HIL.Random with SPARK_Mode => On is

   procedure initialize is
   begin
      STM32.RNG.Polling.Initialize_RNG;
   end;

   procedure Get_Unsigned (num : out Unsigned_32) is
   begin
      num := STM32.RNG.Polling.Random;
   end;

end HIL.Random;
