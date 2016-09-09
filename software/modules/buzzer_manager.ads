--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with Units; use Units;

--  @summary
--  Interface to use a buzzer/beeper.
package Buzzer_Manager with SPARK_Mode is

   subtype T_Name is Character
     with Static_Predicate => T_Name in 'a' .. 'g'; -- c,d,e,f,g,a,b
   subtype T_Octave is Integer range 3 .. 8;
   type Tone_Type is record
      name   : T_Name;
      octave : T_Octave; -- 3=small octave
   end record;
   --  A4 = 440Hz

   type Song_Type is array (Positive range <>) of Tone_Type;

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

   procedure Set_Tone (t : Tone_Type);

   procedure Set_Song (s : Song_Type);

   function Tone_To_Frequency (tone : Tone_Type) return Frequency_Type;
   --  compute the frequency for the given tone name.
   --  Examples:
   --   a' => 400

   procedure Set_Timing (period : in Time_Type; length : in Time_Type)
     with Pre => period > length and
     period > 0.0 * Second and
     length > 0.0 * Second;
   --  define how often and how long the beep appears

private
   procedure Reconfigure_Buzzer;

end Buzzer_Manager;
