
-- todo: initialize in several functions: initGPIO, initI2C, use HAL


-- with Config; use Config;

with HIL.GPIO;
with HIL.SPI;
with HIL.Clock;
with HIL.UART;


package body CPU is

   -- configures hardware registers
   procedure initialize is
   begin

      --  Configure GPIO
      HIL.Clock.configure;

      HIL.GPIO.configure;
      HIL.SPI.configure;
      HIL.UART.configure;


   end initialize;

   procedure sleep is
   begin
      null;
   end sleep;

end CPU;
