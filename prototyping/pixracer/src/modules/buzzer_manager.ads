--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with Units; use Units;

--  @summary
--  Interface to use a buzzer/beeper.
package Buzzer_Manager is

   procedure Initialize;

   procedure Tick;
   --  call this periodically to manage the buzzer

   procedure Enable;
   --  make it shout, whatever was comanded with Set_Freq and Set_Timing

   procedure Disable;
   --  make it silent

   procedure Set_Freq (f : in Frequency_Type)
     with Pre => f > 0.0 * Hertz;
   --  define the frequency of the beep in Hertz

   procedure Set_Timing (period : in Time_Type; length : in Time_Type)
     with Pre => period > length and
     period > 0.0 * Second and
     length > 0.0 * Second;
   --  define how often and how long the beep appears

private
   procedure Reconfigure_Hardware_Timer;

end Buzzer_Manager;
