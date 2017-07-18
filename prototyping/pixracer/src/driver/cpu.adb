
--  todo: initialize in several functions: initGPIO, initI2C, use HAL

with HIL.GPIO;
with HIL.Clock;
with HIL.SPI;
with HIL.UART;
with HIL.I2C;
with HIL.Random;
with Ada.Real_Time;   use Ada.Real_Time;
with STM32.DWT;

package body CPU with SPARK_Mode is

   --  configures hardware registers
   procedure initialize is
      startup_time : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      HIL.Clock.configure;
      HIL.Random.initialize;
      HIL.UART.configure;
      HIL.GPIO.configure;
      HIL.SPI.configure;
      --  HIL.I2C.initialize;
      delay until startup_time + Ada.Real_Time.Milliseconds (200);
      HIL.I2C.initialize;
      STM32.DWT.Enable_Cycle_Counter;
   end initialize;

end CPU;
