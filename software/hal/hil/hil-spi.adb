
with STM32.SPI;
with STM32.Device;
with HAL.SPI;

package body HIL.SPI is

   
   
   procedure configure is
      Config : STM32.SPI.SPI_Configuration := (
					       Direction => STM32.SPI.D2Lines_FullDuplex,
					       Mode => STM32.SPI.Master,
					       Data_Size => HAL.SPI.Data_Size_8b,
					       Clock_Polarity => STM32.SPI.High,
					       Clock_Phase => STM32.SPI.P1Edge,
					       Slave_Management => STM32.SPI.Software_Managed,
					       Baud_Rate_Prescaler => STM32.SPI.BRP_16,
					       First_Bit => STM32.SPI.MSB,
					       CRC_Poly => 16#00#);
						
					       
   begin
      STM32.SPI.Configure(Port => STM32.Device.SPI_1, Conf => Config);
      
      -- enable clock
      STM32.Device.Enable_Clock( STM32.Device.SPI_1 );
   end configure;
      

   procedure write (Device : Device_ID_Type; Data : Data_Type) is
      i : Natural := 0;
   begin
      case (Device) is
      when Barometer => 
	 for i in Data'Range loop
	    STM32.SPI.Transmit(STM32.Device.SPI_1, HAL.Byte( Data(i) ) );
	 end loop;
      when others => null;
      end case;
   end write;
   

   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is
   begin
      null;
   end read;
     


end HIL.SPI;
