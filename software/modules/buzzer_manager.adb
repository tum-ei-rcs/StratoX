--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with HIL.Timers; use HIL.Timers;
with HIL.Devices;
with HIL.Devices.Timers;
with Ada.Real_Time; use Ada.Real_Time;

--  @summary
--  Interface to use a buzzer/beeper.
package body Buzzer_Manager is

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
               HIL.Timers.Enable (HIL.Devices.Timers.Timer_Buzzer);
               t_next := now + Milliseconds (Integer (cur_length * 1000.0));
            when others =>
               HIL.Timers.Disable (HIL.Devices.Timers.Timer_Buzzer);
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
      Reconfigure_Hardware_Timer; -- apply defaults
   end Initialize;

   procedure Disable is
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      Change_State (BOFF, now);
   end Disable;

   procedure Reconfigure_Hardware_Timer is
   begin
      Configure_OC_Toggle (This => HIL.Devices.Timers.Timer_Buzzer,
                           Channel => HIL.Devices.Timers.Timerchannel_Buzzer,
                           Frequency => cur_freq);
      is_configured := True;
   end Reconfigure_Hardware_Timer;

   procedure Set_Freq (f : in Frequency_Type) is
   begin
      cur_freq := f;
      Reconfigure_Hardware_Timer;
   end Set_Freq;

   procedure Set_Timing (period : in Time_Type; length : in Time_Type) is
   begin
      cur_pause := period - length;
      cur_length := length;
   end Set_Timing;

end Buzzer_Manager;
