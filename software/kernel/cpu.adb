
-- todo: initialize in several functions: initGPIO, initI2C, use HAL


with Config; use Config;

with HIL.GPIO;
with STM32_SVD.RCC;   use STM32_SVD.RCC;



package body CPU is

	-- configures hardware registers
	procedure initialize is
	begin
      --  Enable clock for GPIO-E
      RCC_Periph.AHB1ENR.GPIOEEN := True;

      --  Configure GPIO
      HIL.GPIO.configure;
	end initialize;

	procedure sleep is
	begin
		null;
	end sleep;

end CPU;
