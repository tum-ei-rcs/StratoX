
--  todo: initialize in several functions: initGPIO, initI2C, use HAL

with HIL.GPIO;
with HIL.Clock;
with HIL.SPI;
with HIL.UART;

package body CPU is

   --  configures hardware registers
   procedure initialize is
   begin
      --  Configure GPIO
      HIL.Clock.configure;
      HIL.GPIO.configure;
      HIL.UART.configure;
      HIL.SPI.configure;
      --  HIL.I2C.initialize;

   end initialize;

end CPU;
