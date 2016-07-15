-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Software Configuration
--
-- Authors: Martin Becker (becker@rcs.ei.tum.de)
with STM32.Timers;
with STm32.Device;

--  @summary
--  Target-specific types for the hardware timers in Pixhawk.
package HIL.Devices.Timers with SPARK_Mode is
   subtype HIL_Timer is STM32.Timers.Timer;
   subtype HIL_Timer_Channel is STM32.Timers.Timer_Channel;

   -- the buzzer is routed to Timer 2 channel 1:
   Timer_Buzzer : STM32.Timers.Timer renames STM32.Device.Timer_2;
   Timerchannel_Buzzer : STM32.Timers.Timer_Channel := STM32.Timers.Channel_1;

end HIL.Devices.Timers;
