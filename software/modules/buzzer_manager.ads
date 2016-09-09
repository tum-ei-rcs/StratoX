--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with Units; use Units;

--  @summary
--  Interface to use a buzzer/beeper.
package Buzzer_Manager with SPARK_Mode is

--     subtype T_Name is Character
--       with Static_Predicate => T_Name in 'a' .. 'g'; -- c,d,e,f,g,a,b
--     subtype T_Octave is Integer range 3 .. 8;
--     type Tone_Type is record
--        name   : T_Name;
--        octave : T_Octave; -- 3=small octave
--     end record;
--     --  A4 = 440Hz
--
--     type Song_Type is array (Positive range <>) of Tone_Type;

   procedure Initialize;

   procedure Tick;
   --  call this periodically to manage the buzzer

   function Valid_Frequency (f : Frequency_Type) return Boolean is (f > 0.0 * Hertz);

--     procedure Set_Tone (t : Tone_Type);
--
--     function Tone_To_Frequency (tone : Tone_Type) return Frequency_Type;
--     --  compute the frequency for the given tone name.
--     --  Examples:
--     --   a' => 400

   procedure Beep (f : in Frequency_Type; Reps : Natural; Period : Time_Type; Length : in Time_Type);
   --  beep given number of times. If reps = 0, then infinite.

private
   procedure Reconfigure_Buzzer;

end Buzzer_Manager;
