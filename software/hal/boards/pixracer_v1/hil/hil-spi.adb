--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
pragma SPARK_Mode (Off);

with STM32.Device;
with STM32.SPI;
with HAL.SPI;
with HIL.GPIO;

--  @summary
--  target-specific mapping for HIL of SPI
package body HIL.SPI with
   SPARK_Mode => Off
   -- Refined_State => (Deselect => (SIGNAL_DESELECT) ) 
is
      
   SIGNAL_DESELECT : constant HIL.GPIO.GPIO_Signal_Type := HIL.GPIO.HIGH;
   SIGNAL_SELECT   : constant HIL.GPIO.GPIO_Signal_Type := HIL.GPIO.LOW;
      
   procedure configure is
      --  SPI Mode 0 (Polarity=0, Phase=0/Edge=1)
      Config : constant STM32.SPI.SPI_Configuration := 
      ( Direction => STM32.SPI.D2Lines_FullDuplex,
        Mode => STM32.SPI.Master,
        Data_Size => HAL.SPI.Data_Size_8b,
        Clock_Polarity => STM32.SPI.Low,
        Clock_Phase => STM32.SPI.P1Edge,
        Slave_Management => STM32.SPI.Software_Managed,
        Baud_Rate_Prescaler => STM32.SPI.BRP_256,  -- BR = 168 / (2*PreScale); max 20 MHz for Baro; FRAM can do 40MHz
        First_Bit => STM32.SPI.MSB,
        CRC_Poly => 16#00#);
   begin
      --  SPI 2 (Baro, FRAM)
      STM32.Device.Enable_Clock (STM32.Device.SPI_2);        
      STM32.SPI.Configure (Port => STM32.Device.SPI_2, Conf => Config);
      STM32.SPI.Enable (STM32.Device.SPI_2 );      
   end configure;
      

   -- postcondition: only drive pin low
   procedure select_Chip(Device : Device_ID_Type) is
   begin
      case (Device) is
         when Barometer => 
            HIL.GPIO.write (HIL.GPIO.SPI_CS_BARO, SIGNAL_SELECT);
         when FRAM =>
            HIL.GPIO.write (HIL.GPIO.SPI_CS_FRAM, SIGNAL_SELECT);
      end case;
   end select_Chip;
      
   -- postcondition: only drive pin high
   procedure deselect_Chip(Device : Device_ID_Type) is
   begin
      case (Device) is
         when Barometer => 
            HIL.GPIO.write (HIL.GPIO.SPI_CS_BARO, SIGNAL_DESELECT);
         when FRAM =>
            HIL.GPIO.write (HIL.GPIO.SPI_CS_FRAM, SIGNAL_DESELECT);
      end case;
   end deselect_Chip;

   procedure write (Device : Device_ID_Type; Data : Data_Type) is
   begin
      select_Chip(Device);
      case (Device) is
         when Barometer | FRAM => 
            for i in Data'Range loop
               STM32.SPI.Transmit(STM32.Device.SPI_2, HAL.Byte( Data(i) ) );
            end loop;                             
      end case;
      deselect_Chip(Device);      
   end write;  

   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is  
   begin
      select_Chip (Device);
      case (Device) is
         when Barometer | FRAM => 
            for i in Data'Range loop
               STM32.SPI.Receive (STM32.Device.SPI_2, HAL.Byte (Data(i)));
            end loop;                           
      end case;
      deselect_Chip(Device);  
   end read;    
     
   procedure transfer (Device : in Device_ID_Type; Data_TX : in Data_Type; Data_RX : out Data_Type) is
   begin
      select_Chip (Device);
      case (Device) is
      when Barometer | FRAM => 
         -- the following function assumes TX'Length = RX'Length
--  	 STM32.SPI.Transmit_Receive(
--                               STM32.Device.SPI_2, 
--                               STM32.SPI.Byte_Buffer (Data_TX),
--                               STM32.SPI.Byte_Buffer (Data_RX),
--                               Positive (Data_TX'Length));
         
         for i in Data_TX'Range loop
            STM32.SPI.Transmit (STM32.Device.SPI_2, HAL.Byte (Data_TX (i)));
         end loop;                             
         for i in Data_RX'Range loop
            STM32.SPI.Receive (STM32.Device.SPI_2, HAL.Byte (Data_RX (i)));
         end loop;    
      end case;
      deselect_Chip(Device);
   end transfer;


end HIL.SPI;
