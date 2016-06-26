
--  todo: initialize in several functions: initGPIO, initI2C, use HAL

with HIL.GPIO;
with HIL.Clock;
with HIL.SPI;

package body CPU is

   --  configures hardware registers
   procedure initialize is
   begin
      --  Configure GPIO
      HIL.Clock.configure;
      --  HIL.UART.configure;
      --  Logger.log(Logger.DEBUG, "Startup...");

      HIL.GPIO.configure;
      HIL.SPI.configure;
      --  HIL.I2C.initialize;

      --  Logger.log(Logger.DEBUG, "Hardware initialized.");


   end initialize;

end CPU;
