
with stm32.gpio;
with Bit_Types; use Bit_Types;

package HAL.GPIO
with SPARK_Mode
is
   pragma Preelaborate;


   type GPIO_Port_Type is (A, B, C, D, E, F);
   subtype GPIO_Pin_Type is Integer range 1 .. 16;

   type GPIO_Point_Type is record
      Port : GPIO_Port_Type;
      Pin  : GPIO_Pin_Type;
   end record;

   type GPIO_Signal_Type is (LOW, HIGH);

   -- precondition: only write if direction is output (ghost code)
   procedure write (Point : GPIO_Point_Type; Signal : GPIO_Signal_Type);
   -- with pre => stm32.gpio.GPIOA_Periph.MODER.Arr(Point.Pin) = stm32.gpio.Mode_OUT;


   function read (Point : GPIO_Point_Type) return GPIO_Signal_Type;


--     function map(Point : GPIO_Point_Type) return stm32.gpio.GPIO_Peripheral
--     is ( case Point.Port is
--            when A => stm32.gpio.GPIOA_Periph,
--            when B => stm32.gpio.GPIOB_Periph,
--            when C => stm32.gpio.GPIOC_Periph,
--            when D => stm32.gpio.GPIOD_Periph,
--            when E => stm32.gpio.GPIOE_Periph,
--            when F => stm32.gpio.GPIOF_Periph );



end HAL.GPIO;
