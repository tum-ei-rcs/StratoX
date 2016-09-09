-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Martin Becker (becker@rcs.ei.tum.de>
with Units;

--  @summary
--  Target-independent specification for simple HIL of Piezo Buzzer
package HIL.Buzzer with SPARK_Mode is

   procedure Initialize;

   procedure Enable;

   procedure Disable;

   procedure Set_Frequency (Frequency : Units.Frequency_Type)
     with Pre => Frequency in 1.0 .. 1_000_000.0;

end HIL.Buzzer;
