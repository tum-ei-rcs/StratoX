
-- todo: initialize in several functions: initGPIO, initI2C, use HAL


with Config; use Config;

with STM32_SVD.GPIO;  use STM32_SVD.GPIO;
with STM32_SVD.RCC;   use STM32_SVD.RCC;

package body CPU is

	-- configures hardware registers
	procedure initialize is
	begin
      --  Enable clock for GPIO-E
      RCC_Periph.AHB1ENR.GPIOEEN := True;

      --  Configure LED Pin
      GPIOE_Periph.MODER.Arr   (LED_PIN) := Mode_OUT;
      GPIOE_Periph.OTYPER.OT.Arr  (LED_PIN) := Type_PP;
      GPIOE_Periph.OSPEEDR.Arr (LED_PIN) := Speed_100MHz;
      GPIOE_Periph.PUPDR.Arr   (LED_PIN) := No_Pull;
	end initialize;

	procedure sleep is
	begin
		null;
	end sleep;

end CPU;
