--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with HIL.Buzzer;
with Ada.Real_Time; use Ada.Real_Time;

--  @summary
--  Interface to use a buzzer/beeper.
package body Buzzer_Manager with SPARK_Mode is

   type state is (BOFF, BINIT, BDUTY, BWAIT);

   cur_state  : state := BOFF;
   cur_length : Time_Type := 0.1 * Second;
   cur_pause  : Time_Type := 1.9 * Second;
   cur_freq   : Frequency_Type := 1000.0 * Hertz;

   t_next : Ada.Real_Time.Time;

   is_configured  : Boolean := False;

   procedure Enable is
   begin
      if is_configured and cur_state = BOFF then
         cur_state := BINIT;
         t_next := Ada.Real_Time.Clock;
      end if;
   end Enable;

   procedure Change_State (newstate : state; now : Ada.Real_Time.Time);
   procedure Change_State (newstate : state; now : Ada.Real_Time.Time) is
   begin
      --  what do we have to do?
      if cur_state /= newstate then
         case newstate is
            when BDUTY =>
               HIL.Buzzer.Enable;
               t_next := now + Milliseconds (Integer (cur_length * 1000.0));
            when others =>
               HIL.Buzzer.Disable;
               t_next := now + Milliseconds (Integer (cur_pause * 1000.0));
         end case;
         cur_state := newstate;
      end if;
   end Change_State;

   procedure Tick is
      next_state : state;
      now : Ada.Real_Time.Time;
   begin
      if cur_state /= BOFF then
         now := Ada.Real_Time.Clock;
         if now >= t_next then
            case cur_state is
            when BWAIT => next_state := BDUTY;
            when BDUTY => next_state := BWAIT;
            when others => next_state := BDUTY;
            end case;
            Change_State (next_state, now);
         end if;
      end if;
   end Tick;

   procedure Initialize is
   begin
      HIL.Buzzer.Initialize;
      Reconfigure_Buzzer; -- apply defaults
   end Initialize;

   procedure Disable is
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      Change_State (BOFF, now);
   end Disable;

   procedure Reconfigure_Buzzer is
   begin
      HIL.Buzzer.Set_Frequency (cur_freq);
      is_configured := True;
   end Reconfigure_Buzzer;

   function Tone_To_Frequency (tone : Tone_Type) return Frequency_Type is
      f : Frequency_Type;
      subtype octave_modifier is Unit_Type;
      o : constant octave_modifier := octave_modifier (tone.octave - 2);
   begin
      --  frequencies for octave 3 (small octave)
      case tone.name is
         when 'c' => f := 130.813 * Hertz;
         when 'd' => f := 146.832 * Hertz;
         when 'e' => f := 164.814 * Hertz;
         when 'f' => f := 174.614 * Hertz;
         when 'g' => f := 195.998 * Hertz;
         when 'a' => f := 220.000 * Hertz;
         when 'b' => f := 246.942 * Hertz;
      end case;
      --  now multiply with octave above 3
      f := f * o;
      return f;
   end Tone_To_Frequency;

   procedure Set_Tone (t : Tone_Type) is
      f : constant Frequency_Type := Tone_To_Frequency (t);
   begin
      Set_Freq (f);
   end Set_Tone;

   procedure Set_Song (s : Song_Type) is
   begin
      null;
   end Set_Song;

   procedure Set_Freq (f : in Frequency_Type) is
   begin
      cur_freq := f;
      Reconfigure_Buzzer;
   end Set_Freq;

   procedure Set_Timing (period : in Time_Type; length : in Time_Type) is
   begin
      cur_pause := period - length;
      cur_length := length;
   end Set_Timing;

end Buzzer_Manager;
