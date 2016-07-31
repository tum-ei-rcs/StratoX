
-- todo: initialize in several functions: initGPIO, initI2C, use HAL


-- with Config; use Config;

with HIL.GPIO;
with HIL.SPI;
with HIL.Clock;
with HIL.UART;
with HIL.I2C;
with Ada.Real_Time; use Ada.Real_Time;


package body CPU is

   -- configures hardware registers
   procedure initialize is
      startup_time : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin

      --  Configure GPIO
      HIL.Clock.configure;
      HIL.UART.configure;
      HIL.GPIO.configure;
      HIL.SPI.configure;

      delay until startup_time + Ada.Real_Time.Milliseconds (200);
      HIL.I2C.initialize;

   end initialize;

   procedure sleep is
   begin
      null;
   end sleep;

end CPU;
