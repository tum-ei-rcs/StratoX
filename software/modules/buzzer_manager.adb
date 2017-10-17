--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with HIL.Buzzer;
with Ada.Real_Time; use Ada.Real_Time;
with Types;

--  @summary
--  Interface to use a buzzer/beeper.
package body Buzzer_Manager with SPARK_Mode is

   type state is (BOFF, BINIT, BDUTY, BWAIT);

   --------------------
   --  internal state
   --------------------

   cur_state  : state := BOFF;

   cur_length_ms : Natural := 100;
   cur_pause_ms : Natural  := 1900;
   cur_freq   : Frequency_Type := 1000.0 * Hertz;
   cur_reps   : Natural := 0;
   infinite   : Boolean := False;
   t_next     : Ada.Real_Time.Time;

   is_configured  : Boolean := False;

   --------------
   --  specs
   --------------

   procedure Change_State (newstate : state; now : Ada.Real_Time.Time);
   procedure Set_Freq (f : in Frequency_Type) with Pre => Valid_Frequency (f);
   procedure Enable_Statemachine;
   procedure Disable_Statemachine;

   -------------------------
   -- Enable_Statemachine --
   -------------------------

   procedure Enable_Statemachine is
   begin
      if is_configured and cur_state = BOFF then
         cur_state := BINIT;
         t_next := Ada.Real_Time.Clock;
      end if;
   end Enable_Statemachine;

   ------------------
   -- Change_State --
   ------------------

   procedure Change_State (newstate : state; now : Ada.Real_Time.Time) is
      cand_newstate : state := newstate;
   begin
      if cur_state /= newstate then
         case newstate is
            when BDUTY =>
               if not infinite then
                  --  finite mode...countdown
                  if cur_reps > 0 then
                     cur_reps := cur_reps - 1;
                     HIL.Buzzer.Enable;
                  else
                     HIL.Buzzer.Disable;
                     cand_newstate := BOFF;
                  end if;
               else
                  --  infinite mode
                  HIL.Buzzer.Enable;
               end if;

               t_next := now + Milliseconds (cur_length_ms);
            when others =>
               HIL.Buzzer.Disable;
               t_next := now + Milliseconds (cur_pause_ms);
         end case;
         cur_state := cand_newstate;
      end if;
   end Change_State;

   ----------
   -- Tick --
   ----------

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

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      HIL.Buzzer.Initialize;
      Reconfigure_Buzzer; -- apply defaults
      HIL.Buzzer.Disable;
   end Initialize;

   --------------------------
   -- Disable_Statemachine --
   --------------------------

   procedure Disable_Statemachine is
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      infinite := False;
      Change_State (BOFF, now);
   end Disable_Statemachine;

   ------------------------
   -- Reconfigure_Buzzer --
   ------------------------

   procedure Reconfigure_Buzzer is
   begin
      if HIL.Buzzer.Valid_Frequency (cur_freq) then
         HIL.Buzzer.Set_Frequency (cur_freq);
         is_configured := True;
      end if;
   end Reconfigure_Buzzer;

--     function Tone_To_Frequency (tone : Tone_Type) return Frequency_Type is
--        f : Frequency_Type;
--        subtype octave_modifier is Unit_Type;
--        o : constant octave_modifier := octave_modifier (tone.octave - 2);
--     begin
--        --  frequencies for octave 3 (small octave)
--        case tone.name is
--           when 'c' => f := 130.813 * Hertz;
--           when 'd' => f := 146.832 * Hertz;
--           when 'e' => f := 164.814 * Hertz;
--           when 'f' => f := 174.614 * Hertz;
--           when 'g' => f := 195.998 * Hertz;
--           when 'a' => f := 220.000 * Hertz;
--           when 'b' => f := 246.942 * Hertz;
--        end case;
--        --  now multiply with octave above 3
--        f := f * o;
--        return f;
--     end Tone_To_Frequency;
--
--     procedure Set_Tone (t : Tone_Type) is
--        f : constant Frequency_Type := Tone_To_Frequency (t);
--     begin
--        Set_Freq (f);
--     end Set_Tone;

   --------------
   -- Set_Freq --
   --------------

   procedure Set_Freq (f : in Frequency_Type) is
   begin
      cur_freq := f;
      Reconfigure_Buzzer;
   end Set_Freq;

   ----------
   -- Beep --
   ----------

   procedure Beep
     (f      : in Frequency_Type;
      Reps   : Natural;
      Period : Time_Type;
      Length : in Time_Type)
   is
      function Sat_Sub_Time is new
        Units.Saturated_Subtraction (Time_Type);

      function To_Millisec (t : Time_Type) return Natural;
      function To_Millisec (t : Time_Type) return Natural is
         ms : Float;
      begin
         if abs (Float (t)) >= Float'Last / 1000.0 then
            ms := Float'Last;
         else
            ms := Float (t) * 1000.0;
         end if;
         return Types.Sat_Cast_Natural (ms);
      end To_Millisec;

   begin
      if not Valid_Frequency (f) or
        Period <= Length or
        Period = 0.0 * Second or
        Length = 0.0 * Second
      then
         Disable_Statemachine;
         return;
      end if;

      cur_reps := Reps;
      infinite := (Reps = 0);
      declare
         cur_pause  : constant Time_Type := Sat_Sub_Time (Period, Length);
         cur_length : constant Time_Type := Length;
      begin
         cur_pause_ms  := To_Millisec (cur_pause);
         cur_length_ms := To_Millisec (cur_length);
      end;

      if f /= cur_freq then
         Set_Freq (f);
      end if;

      Enable_Statemachine;
   end Beep;

end Buzzer_Manager;
