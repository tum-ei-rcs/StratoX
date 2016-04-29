

with STM32.UART;
with STM32.Device;
with HAL.UART;

package body HIL.UART is
   
   procedure configure is 
   begin
      STM32.UART.Enable();
     null;  
   end configure;
      

   procedure write (Device : in Device_ID_Type; Data : in Data_Type) is
   begin
      null;
   end write;
   

   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is
   begin
      null;
   end read;
   

   function toData_Type( Message : String ) return Data_Type is
   begin
      return (1 => 0);
   end toData_Type;
   
end HIL.UART;
