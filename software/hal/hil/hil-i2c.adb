

with STM32.I2C;
with STM32.Device;

package body HIL.I2C is



   procedure initialize is
      Config : STM32.I2C.I2C_Configuration := (
					       Clock_Speed => 44,
					       Addressing_Mode => STM32.I2C.Addressing_Mode_7bit,
					       Own_Address => 16#00#
					       );				       
   begin
   	STM32.I2C.Configure(STM32.Device.I2C_1, Config);
   end initialize;

   procedure write (Device : in Device_Type; Data : in Data_Type) is
   begin
      null;
   end write;
   
   procedure read (Device : in Device_Type; Data : out Data_Type) is
   begin
      null;
   end read;
   

   procedure transfer (Device : in Device_Type; Data_TX : in Data_Type; Data_RX : in Data_Type) is
   begin
      null;
   end transfer;

end HIL.I2C;
