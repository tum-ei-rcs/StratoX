
with STM32.SPI; use STM32.SPI;
with STM32.GPIO;
with STM32.Device;
with HAL.SPI;
with HIL.GPIO;

package body HIL.SPI is

 
--     function baudRate(rate : Natural) return SPI_Baud_Rate_Prescaler is
--     begin
--        return 24_000_000 / (16 * rate);
--     end baudRate;
      
   
   
   
   procedure configure is
      Config : STM32.SPI.SPI_Configuration := (
					       Direction => STM32.SPI.D2Lines_FullDuplex,
					       Mode => STM32.SPI.Master,
					       Data_Size => HAL.SPI.Data_Size_8b,
					       Clock_Polarity => STM32.SPI.Low,
					       Clock_Phase => STM32.SPI.P1Edge,
					       Slave_Management => STM32.SPI.Software_Managed,
                                               Baud_Rate_Prescaler => STM32.SPI.BRP_256,  -- BR = 168 / (2*PreScale)  ; max 20 MHz for Baro
					       First_Bit => STM32.SPI.MSB,
					       CRC_Poly => 16#00#);
						
					       
   begin
       -- SPI 1 (Baro)
      STM32.Device.Enable_Clock( STM32.Device.SPI_1 );  
   
      STM32.SPI.Configure(Port => STM32.Device.SPI_1, Conf => Config);
      STM32.SPI.Enable( STM32.Device.SPI_1 );
      
      -- SPI 4 (Extern)
      STM32.Device.Enable_Clock( STM32.Device.SPI_4 );  
   
      STM32.SPI.Configure(Port => STM32.Device.SPI_4, Conf => Config);
      STM32.SPI.Enable( STM32.Device.SPI_4 );     
      

   end configure;
      


   procedure select_Chip(Device : Device_ID_Type) is
   begin
      case (Device) is
      when Barometer => 
         HIL.GPIO.write(HIL.GPIO.SPI_CS_BARO, HIL.GPIO.LOW);
      when Extern =>
         HIL.GPIO.write(HIL.GPIO.SPI_CS_EXT, HIL.GPIO.LOW);
      when others => null;
      end case;
   end select_Chip;
      

   procedure deselect_Chip(Device : Device_ID_Type) is
   begin
      case (Device) is
      when Barometer => 
         HIL.GPIO.write(HIL.GPIO.SPI_CS_BARO, HIL.GPIO.HIGH);
      when Extern =>
         HIL.GPIO.write(HIL.GPIO.SPI_CS_EXT, HIL.GPIO.HIGH);
      when others => null;
      end case;
   end deselect_Chip;


   procedure write (Device : Device_ID_Type; Data : Data_Type) is
      i : Natural := 0;
   begin
      case (Device) is
      when Barometer => 
         for i in Data'Range loop
	    STM32.SPI.Transmit(STM32.Device.SPI_1, HAL.Byte( Data(i) ) );
         end loop;
       when Extern => 
         for i in Data'Range loop
	    STM32.SPI.Transmit(STM32.Device.SPI_4, HAL.Byte( Data(i) ) );
         end loop;       
      when others => null;
      end case;
   end write;
   

   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is  
   begin
      null;
   end read;
     
     
   procedure transfer (Device : in Device_ID_Type; Data_TX : in Data_Type; Data_RX : out Data_Type) is
   begin
       case (Device) is
      when Barometer => 
	 STM32.SPI.Transmit_Receive(
                             STM32.Device.SPI_1, 
                             STM32.SPI.Byte_Buffer( Data_TX ),
                             STM32.SPI.Byte_Buffer( Data_RX ),
                             Positive( Data_TX'Length ) );
       when Extern => 
	 STM32.SPI.Transmit_Receive(
                             STM32.Device.SPI_4, 
                             STM32.SPI.Byte_Buffer( Data_TX ),
                             STM32.SPI.Byte_Buffer( Data_RX ),
                             Positive( Data_TX'Length ) );                      
      when others => null;
      end case;   
   end transfer;


end HIL.SPI;
