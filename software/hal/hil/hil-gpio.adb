
with STM32.GPIO;  use STM32.GPIO;
with STM32.Device;

package body HIL.GPIO is


   function map(Point : GPIO_Point_Type) return GPIO_Point is
      ( case Point is
      when RED_LED => STM32.Device.PE12 );
   -- function map(Signal : GPIO_Signal_Type) return GPIO_Signal_Type;


   procedure write (Point : GPIO_Point_Type; Signal : GPIO_Signal_Type) is
      stm32_point : GPIO_Point := map( Point );
   begin
      case (Signal) is
         when LOW  => STM32.GPIO.Clear( stm32_point  );
         when HIGH => STM32.GPIO.Set( stm32_point  );
      end case;
   end write;


   procedure configure is
      Config_Out : constant GPIO_Port_Configuration := (
         Mode => Mode_Out,
         Output_Type => Push_Pull,
         Speed => Speed_50MHz,
         Resistors => Floating );
   begin
      -- configure LED
      Configure_IO( Points => (1 => map(RED_LED)), Config => Config_Out );

   end configure;


--     function map(Point : GPIO_Point_Type) return GPIO_Points is
--     begin
--        case Point is
--        when RED_LED => (Periph => STM32_SVD.GPIO.GPIOE_Periph, Pin => 12);
--        end case;
--     end map;


   -- function map(Signal : GPIO_Signal_Type) return HAL.GPIO.GPIO_Signal_Type
   -- is (case Signal is
   --        when HIGH => HAL.GPIO.HIGH,
   --        when LOW => HAL.GPIO.LOW );



end HIL.GPIO;
