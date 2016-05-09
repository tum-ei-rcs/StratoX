
with STM32.Device;

package body HIL.Clock is

   procedure configure is
   begin
      -- GPIOs
      STM32.Device.Enable_Clock( STM32.Device.GPIO_A );
      STM32.Device.Enable_Clock(STM32.Device.GPIO_B);
      STM32.Device.Enable_Clock(STM32.Device.GPIO_C);
      STM32.Device.Enable_Clock(STM32.Device.GPIO_D);
      STM32.Device.Enable_Clock(STM32.Device.GPIO_E);   
      
      -- SPI
      STM32.Device.Enable_Clock(STM32.Device.SPI_1);
      
      -- I2C
      
      
      -- UART (UART3 is Ser2 is Telemtrie2)
      STM32.Device.Enable_Clock( STM32.Device.USART_3 );
      STM32.Device.Enable_Clock( STM32.Device.USART_7 );   -- SER 5
 
 
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
