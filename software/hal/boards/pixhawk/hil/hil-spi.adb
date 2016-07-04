--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
pragma SPARK_Mode (Off);

with STM32.Device;
with STM32.SPI;
with HAL.SPI;
with HIL.GPIO;

--  @summary
--  Target-specific mapping for HIL of SPI
package body HIL.SPI with
   SPARK_Mode => Off
   -- Refined_State => (Deselect => (SIGNAL_DESELECT) ) 
is

 
--     function baudRate(rate : Natural) return SPI_Baud_Rate_Prescaler is
--     begin
--        return 24_000_000 / (16 * rate);
--     end baudRate;
      
   SIGNAL_DESELECT : constant HIL.GPIO.GPIO_Signal_Type := HIL.GPIO.HIGH;
   SIGNAL_SELECT : constant HIL.GPIO.GPIO_Signal_Type := HIL.GPIO.LOW;
   
   
   procedure configure is
      Config : constant STM32.SPI.SPI_Configuration := 
      ( Direction => STM32.SPI.D2Lines_FullDuplex,
        Mode => STM32.SPI.Master,
        Data_Size => HAL.SPI.Data_Size_8b,
        Clock_Polarity => STM32.SPI.Low,
        Clock_Phase => STM32.SPI.P1Edge,
        Slave_Management => STM32.SPI.Software_Managed,
        Baud_Rate_Prescaler => STM32.SPI.BRP_256,  -- BR = 168 / (2*PreScale); max 20 MHz for Baro
        First_Bit => STM32.SPI.MSB,
        CRC_Poly => 16#00#);
                                            
						
					       
   begin
      -- SPI 1 (Baro, MPU6000?)
      STM32.Device.Enable_Clock( STM32.Device.SPI_1 );  
   
      STM32.SPI.Configure(Port => STM32.Device.SPI_1, Conf => Config);
      STM32.SPI.Enable( STM32.Device.SPI_1 );
      
      
      -- SPI 2 (NVRAM)
      STM32.Device.Enable_Clock( STM32.Device.SPI_2 );  
   
      STM32.SPI.Configure(Port => STM32.Device.SPI_2, Conf => Config);
      STM32.SPI.Enable( STM32.Device.SPI_2 ); 
      
      -- SPI 4 (Extern)
      STM32.Device.Enable_Clock( STM32.Device.SPI_4 );  
   
      STM32.SPI.Configure(Port => STM32.Device.SPI_4, Conf => Config);
      STM32.SPI.Enable( STM32.Device.SPI_4 );     
      

   end configure;
      

   -- postcondition: only drive pin low
   procedure select_Chip(Device : Device_ID_Type) is
   begin
      case (Device) is
      when Barometer => 
         HIL.GPIO.write(HIL.GPIO.SPI_CS_BARO, SIGNAL_SELECT);
      when MPU6000 =>
         HIL.GPIO.write(HIL.GPIO.SPI_CS_MPU6000, SIGNAL_SELECT);
      when FRAM =>
         HIL.GPIO.write(HIL.GPIO.SPI_CS_FRAM, SIGNAL_SELECT);
      when Extern =>
         HIL.GPIO.write(HIL.GPIO.SPI_CS_EXT, SIGNAL_SELECT);
      when Magneto =>
         null; -- TODO
      -- dont use "others=>" here for guaranteed coverage
      end case;
   end select_Chip;
      

   -- postcondition: only drive pin high
   procedure deselect_Chip(Device : Device_ID_Type) is
   begin
      case (Device) is
      when Barometer => 
         HIL.GPIO.write(HIL.GPIO.SPI_CS_BARO, SIGNAL_DESELECT);
      when MPU6000 =>
         HIL.GPIO.write(HIL.GPIO.SPI_CS_MPU6000, SIGNAL_DESELECT);
      when Extern =>
         HIL.GPIO.write(HIL.GPIO.SPI_CS_EXT, SIGNAL_DESELECT);
      when FRAM =>
         HIL.GPIO.write(HIL.GPIO.SPI_CS_FRAM, SIGNAL_DESELECT);
      when Magneto =>
         null; -- TODO                          
      -- dont use "others=>" here for guaranteed coverage
      end case;
   end deselect_Chip;


   procedure write (Device : Device_ID_Type; Data : Data_Type) is
   begin
      select_Chip(Device);
      case (Device) is
      when Barometer | MPU6000 => 
         for i in Data'Range loop
            STM32.SPI.Transmit(STM32.Device.SPI_1, HAL.Byte( Data(i) ) );
         end loop;          
      when FRAM =>
         for i in Data'Range loop
            STM32.SPI.Transmit(STM32.Device.SPI_2, HAL.Byte( Data(i) ) );
         end loop;           
      when Extern => 
         for i in Data'Range loop
            STM32.SPI.Transmit(STM32.Device.SPI_4, HAL.Byte( Data(i) ) );
         end loop;  
      when Magneto =>
         null; -- TODO
      end case;
      deselect_Chip(Device);
   end write;
   

   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is  
   begin
      select_Chip(Device);
      case (Device) is
      when Barometer | MPU6000 => 
         for i in Data'Range loop
	    STM32.SPI.Receive (STM32.Device.SPI_1, HAL.Byte( Data(i) ) );
         end loop;  
      when FRAM =>
         for i in Data'Range loop
            STM32.SPI.Receive (STM32.Device.SPI_2, HAL.Byte( Data(i) ) );
         end loop;  
      when Extern => 
         for i in Data'Range loop
	    STM32.SPI.Receive (STM32.Device.SPI_4, HAL.Byte( Data(i) ) );
         end loop;  
      when Magneto =>
         null; -- TODO
      end case;
      deselect_Chip(Device);
   end read;
     
     
   procedure transfer (Device : in Device_ID_Type; Data_TX : in Data_Type; Data_RX : out Data_Type) is
   begin
      select_Chip(Device);
      case (Device) is
         when Barometer | MPU6000 => 
            for i in Data_TX'Range loop
               STM32.SPI.Transmit (STM32.Device.SPI_1, HAL.Byte (Data_TX (i)));
            end loop;                             
            for i in Data_RX'Range loop
               STM32.SPI.Receive (STM32.Device.SPI_1, HAL.Byte (Data_RX (i)));
            end loop; 
         when FRAM =>
            for i in Data_TX'Range loop
               STM32.SPI.Transmit (STM32.Device.SPI_2, HAL.Byte (Data_TX (i)));
            end loop;                             
            for i in Data_RX'Range loop
               STM32.SPI.Receive (STM32.Device.SPI_2, HAL.Byte (Data_RX (i)));
            end loop;                         
         when Extern => 
            for i in Data_TX'Range loop
               STM32.SPI.Transmit (STM32.Device.SPI_4, HAL.Byte (Data_TX (i)));
            end loop;                             
            for i in Data_RX'Range loop
               STM32.SPI.Receive (STM32.Device.SPI_4, HAL.Byte (Data_RX (i)));
            end loop; 
         when Magneto =>
            null; -- TODO
      end case;            
      -- these functions can only be used if Data_TX'Length = Data_RX'Length     
      --        STM32.SPI.Transmit_Receive(
      --                                   STM32.Device.SPI_1, 
      --                                   STM32.SPI.Byte_Buffer( Data_TX ),
      --                                   STM32.SPI.Byte_Buffer( Data_RX ),
      --                                   Positive( Data_TX'Length ) );        
      deselect_Chip(Device);
   end transfer;


   procedure transceive (Device : in Device_ID_Type; Data_TX : in Data_Type; Data_RX : out Data_Type) is
   begin
      select_Chip(Device);
      case (Device) is
         when Barometer | MPU6000 => 
            STM32.SPI.Transmit_Receive(STM32.Device.SPI_1, 
                                       STM32.SPI.Byte_Buffer( Data_TX ),
                                       STM32.SPI.Byte_Buffer( Data_RX ),
                                       Positive( Data_TX'Length ) );    
         when FRAM =>
            STM32.SPI.Transmit_Receive(STM32.Device.SPI_2, 
                                       STM32.SPI.Byte_Buffer( Data_TX ),
                                       STM32.SPI.Byte_Buffer( Data_RX ),
                                       Positive( Data_TX'Length ) );                        
         when Extern => 
            STM32.SPI.Transmit_Receive(STM32.Device.SPI_4, 
                                       STM32.SPI.Byte_Buffer( Data_TX ),
                                       STM32.SPI.Byte_Buffer( Data_RX ),
                                       Positive( Data_TX'Length ) ); 
         when Magneto =>
            null; -- TODO
      end case;
      deselect_Chip(Device);
   end transceive;

end HIL.SPI;
