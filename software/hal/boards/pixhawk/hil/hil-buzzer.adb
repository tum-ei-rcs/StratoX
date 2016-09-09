-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Martin Becker (becker@rcs.ei.tum.de>
with HIL.Config;
with HIL.Timers;
with HIL.Devices.Timers;

--  @summary
--  Target-independent specification for simple HIL of Piezo Buzzer
package body HIL.Buzzer is

   procedure Initialize is
   begin
      case HIL.Config.BUZZER_PORT is
         when HIL.Config.BUZZER_USE_AUX5 =>
            HIL.Timers.Initialize (HIL.Devices.Timers.Timer_Buzzer_Aux);
         when HIL.Config.BUZZER_USE_PORT =>
            HIL.Timers.Initialize (HIL.Devices.Timers.Timer_Buzzer_Port);
      end case;
   end Initialize;

   procedure Enable is
   begin
      case HIL.Config.BUZZER_PORT is
         when HIL.Config.BUZZER_USE_AUX5 =>
            HIL.Timers.Enable (t => HIL.Devices.Timers.Timer_Buzzer_Aux,
                               ch => HIL.Devices.Timers.Timerchannel_Buzzer_Aux);
         when HIL.Config.BUZZER_USE_PORT =>
            HIL.Timers.Enable (t => HIL.Devices.Timers.Timer_Buzzer_Port,
                               ch => HIL.Devices.Timers.Timerchannel_Buzzer_Port);
      end case;
   end Enable;

   procedure Disable is begin
      case HIL.Config.BUZZER_PORT is
         when HIL.Config.BUZZER_USE_AUX5 =>
            HIL.Timers.Disable (t => HIL.Devices.Timers.Timer_Buzzer_Aux);
         when HIL.Config.BUZZER_USE_PORT =>
            HIL.Timers.Disable (t => HIL.Devices.Timers.Timer_Buzzer_Port);
      end case;
   end Disable;

   procedure Set_Frequency (Frequency : Units.Frequency_Type) is
   begin
      case HIL.Config.BUZZER_PORT is
         when HIL.Config.BUZZER_USE_AUX5 =>
            HIL.Timers.Configure_OC_Toggle (This => HIL.Devices.Timers.Timer_Buzzer_Aux,
                                            Channel => HIL.Devices.Timers.Timerchannel_Buzzer_Aux,
                                            Frequency => Frequency);

         when HIL.Config.BUZZER_USE_PORT =>
            HIL.Timers.Configure_OC_Toggle (This => HIL.Devices.Timers.Timer_Buzzer_Port,
                                            Channel => HIL.Devices.Timers.Timerchannel_Buzzer_Port,
                                            Frequency => Frequency);
      end case;

   end Set_Frequency;

end HIL.Buzzer;
