--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with STM32.Device;
with HIL.Config;

--  @summary
--  Target-specific mapping for HIL of Clock
package body HIL.Clock with
   SPARK_Mode => Off 
is

   procedure configure is
   begin
      -- GPIOs
      STM32.Device.Enable_Clock(STM32.Device.GPIO_A );
      STM32.Device.Enable_Clock(STM32.Device.GPIO_B);
      STM32.Device.Enable_Clock(STM32.Device.GPIO_C);
      STM32.Device.Enable_Clock(STM32.Device.GPIO_D);
      STM32.Device.Enable_Clock(STM32.Device.GPIO_E);
      
      -- SPI
      STM32.Device.Enable_Clock(STM32.Device.SPI_1);
      
      -- I2C
      STM32.Device.Enable_Clock( STM32.Device.I2C_1 ); -- I2C
      
      -- UART (UART3 is Ser2 is Telemtrie2)
      STM32.Device.Enable_Clock( STM32.Device.USART_3 );
      STM32.Device.Enable_Clock( STM32.Device.UART_4 );  --  GPS
      STM32.Device.Enable_Clock( STM32.Device.USART_6 );   -- PX4IO 
      STM32.Device.Enable_Clock( STM32.Device.USART_7 );   -- SER 5
 
      -- Timers
      case HIL.Config.BUZZER_PORT is
         when HIL.Config.BUZZER_USE_AUX5 =>
            STM32.Device.Enable_Clock (STM32.Device.Timer_4); -- AUX buzzer
            STM32.Device.Reset (STM32.Device.Timer_4); -- without this not reliable
         when HIL.Config.BUZZER_USE_PORT =>            
            STM32.Device.Enable_Clock (STM32.Device.Timer_2); -- regular buzzer port
            STM32.Device.Reset (STM32.Device.Timer_2); -- without this not reliable
      end case;

      
      STM32.Device.Reset( STM32.Device.GPIO_A );
      STM32.Device.Reset( STM32.Device.GPIO_B );
      STM32.Device.Reset( STM32.Device.GPIO_C );
      STM32.Device.Reset( STM32.Device.GPIO_D );
      STM32.Device.Reset( STM32.Device.GPIO_E );
      
      STM32.Device.Reset( STM32.Device.SPI_1 );
      
      STM32.Device.Reset( STM32.Device.USART_3 );
      STM32.Device.Reset( STM32.Device.UART_4 );
      STM32.Device.Reset( STM32.Device.USART_6 );
      STM32.Device.Reset( STM32.Device.USART_7 );
      
 
   end configure;
   
   

   -- get number of systicks since POR
   function getSysTick return Natural is
   begin
      null;
      return 0;
   end getSysTick;

   -- get system time since POR
   function getSysTime return Ada.Real_Time.Time is
   begin
      return Ada.Real_Time.Clock;
   end getSysTime;

end HIL.Clock;
