
with STM32_SVD.GPIO;  use STM32_SVD.GPIO;
with HAL.GPIO;

package body HIL.GPIO is


   function map(Point : GPIO_Point_Type) return HAL.GPIO.GPIO_Point_Type;
   function map(Signal : GPIO_Signal_Type) return HAL.GPIO.GPIO_Signal_Type;


   procedure write (Point : GPIO_Point_Type; Signal : GPIO_Signal_Type) is
   begin
      HAL.GPIO.write( map(Point),  map(Signal) );
   end write;



   function map(Point : GPIO_Point_Type) return HAL.GPIO.GPIO_Point_Type is (
      case Point is
         when RED_LED => (Port => HAL.GPIO.E, Pin => 12) );


   function map(Signal : GPIO_Signal_Type) return HAL.GPIO.GPIO_Signal_Type
   is (case Signal is
          when HIGH => HAL.GPIO.HIGH,
          when LOW => HAL.GPIO.LOW );



end HIL.GPIO;
