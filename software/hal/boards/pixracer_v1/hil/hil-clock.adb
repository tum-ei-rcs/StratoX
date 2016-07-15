--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with STM32.Device;

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
      STM32.Device.Enable_Clock(STM32.Device.SPI_2);
      
      -- I2C
      --STM32.Device.Enable_Clock( STM32.Device.I2C_1 ); -- I2C
      
      -- USARTs
      STM32.Device.Enable_Clock( STM32.Device.USART_1 );
      STM32.Device.Enable_Clock( STM32.Device.USART_2 );
      STM32.Device.Enable_Clock( STM32.Device.USART_3 );
      STM32.Device.Enable_Clock( STM32.Device.UART_4 );
      STM32.Device.Enable_Clock( STM32.Device.USART_7 );
 
      -- Timers
      STM32.Device.Enable_Clock (STM32.Device.Timer_2);
      STM32.Device.Reset (STM32.Device.Timer_2);
 
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
