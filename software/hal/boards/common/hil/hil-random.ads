--  Institution: Technische Universität München
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker

--  @summary
--  Target-independent specification for HIL of Random number generator
with Interfaces; use Interfaces;

package HIL.Random with SPARK_Mode => On is

   procedure initialize;

   procedure Get_Unsigned (num : out Unsigned_32);

end HIL.Random;
