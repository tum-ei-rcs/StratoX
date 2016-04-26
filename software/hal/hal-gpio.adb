
with stm32.gpio;  use stm32.gpio;

package body HAL.GPIO is



   procedure write (Point : GPIO_Point_Type; Signal : GPIO_Signal_Type) is
   begin
      case Signal is
         when HIGH =>
            case Point.Port is
               when A => GPIOA_Periph.BSRR.BS.Arr( Point.Pin ) := True;
               when B => GPIOB_Periph.BSRR.BS.Arr( Point.Pin ) := True;
               when C => GPIOC_Periph.BSRR.BS.Arr( Point.Pin ) := True;
               when D => GPIOD_Periph.BSRR.BS.Arr( Point.Pin ) := True;
               when E => GPIOE_Periph.BSRR.BS.Arr( Point.Pin ) := True;
               when F => GPIOF_Periph.BSRR.BS.Arr( Point.Pin ) := True;
            end case;
         when LOW =>
            case Point.Port is
               when A => GPIOA_Periph.BSRR.BR.Arr( Point.Pin ) := True;
               when B => GPIOB_Periph.BSRR.BR.Arr( Point.Pin ) := True;
               when C => GPIOC_Periph.BSRR.BR.Arr( Point.Pin ) := True;
               when D => GPIOD_Periph.BSRR.BR.Arr( Point.Pin ) := True;
               when E => GPIOE_Periph.BSRR.BR.Arr( Point.Pin ) := True;
               when F => GPIOF_Periph.BSRR.BR.Arr( Point.Pin ) := True;
            end case;
      end case;
   end write;


   function read (Point : GPIO_Point_Type) return GPIO_Signal_Type is
   begin
      return HIGH;
   end read;

end HAL.GPIO;
