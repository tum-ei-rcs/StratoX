
-- todo: initialize in several functions: initGPIO, initI2C, use HAL


-- with Config; use Config;

with HIL.GPIO;
with HIL.SPI;
with HIL.Clock;
with HIL.UART;
with HIL.I2C;
with Logger;


package body CPU is

   -- configures hardware registers
   procedure initialize is
   begin

      --  Configure GPIO
      HIL.Clock.configure;
      HIL.UART.configure;
      Logger.log(Logger.DEBUG, "Startup...");

      HIL.GPIO.configure;
      HIL.SPI.configure;
      HIL.I2C.initialize;


      Logger.log(Logger.DEBUG, "Hardware initialized.");

   end initialize;

   procedure sleep is
   begin
      null;
   end sleep;

end CPU;
