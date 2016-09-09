-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Martin Becker (becker@rcs.ei.tum.de>

with HIL.Devices.Timers;
with Units; use Units;
with HAL; use HAL;

--  @summary
--  Target-independent specification for simple HIL of Hardware Timers
package HIL.Timers with SPARK_Mode => Off is

   -- TODO: this package is unfinished business. It simply allows to set up
   -- a very basic timer configuration w/o interrupts. This makes sense,
   -- the alternative function of the respective timer is activated as pinout.
   -- In that case, the timer's overflow etc. can be given to a device,
   -- e.g., as square signal to a buzzer, or LED (dimming).

   subtype HIL_Timer is HIL.Devices.Timers.HIL_Timer; -- expose type
   subtype HIL_Timer_Channel is HIL.Devices.Timers.HIL_Timer_Channel;

   procedure Initialize (t : in out HIL_Timer);

   procedure Enable (t : in out HIL_Timer; ch : HIL.Timers.HIL_Timer_Channel);

   procedure Disable (t : in out HIL_Timer; ch : HIL.Timers.HIL_Timer_Channel);

   procedure Configure_OC_Toggle
     (This      : in out HIL_Timer;
      Frequency : Frequency_Type;
      Channel   : HIL_Timer_Channel)
     with Pre => Frequency in 1.0 .. 1_000_000.0;
   --  configure output compare toggle on given timer and channel.
   --  the channel is toggled every time the timer reaches zero.
   --  i.e., the channel shows a 50% square waveform with given
   --  frequency.


   --  procedure Set_Autoreload (This : in out HIL_Timer;  Value : Word);
   --  procedure Set_Counter (This : in out HIL_Timer;  Value : Word);

end HIL.Timers;
