

with STM32.USARTs;
with STM32.Device;
with HAL.UART;

package body HIL.UART is
   
   procedure configure is 
   begin
      -- UART 1
      -- STM32.USARTs.Enable( STM32.Device.USART_1 );
      STM32.USARTs.Set_Stop_Bits( STM32.Device.USART_1, STM32.USARTs.Stopbits_1 );
      STM32.USARTs.Set_Word_Length( STM32.Device.USART_1, STM32.USARTs.Word_Length_8 );
      STM32.USARTs.Set_Parity( STM32.Device.USART_1, STM32.USARTs.No_Parity );
      STM32.USARTs.Set_Baud_Rate( STM32.Device.USART_1, 9_600 );
      STM32.USARTs.Set_Oversampling_Mode( STM32.Device.USART_1, STM32.USARTs.Oversampling_By_16 );
      STM32.USARTs.Set_Mode( STM32.Device.USART_1, STM32.USARTs.Tx_Rx_Mode );
      STM32.USARTs.Set_Flow_Control( STM32.Device.USART_1, STM32.USARTs.No_Flow_Control );

      -- UART 2
      -- STM32.USARTs.Enable( STM32.Device.USART_2 );
      STM32.USARTs.Set_Stop_Bits( STM32.Device.USART_2, STM32.USARTs.Stopbits_1 );
      STM32.USARTs.Set_Word_Length( STM32.Device.USART_2, STM32.USARTs.Word_Length_8 );
      STM32.USARTs.Set_Parity( STM32.Device.USART_2, STM32.USARTs.No_Parity );
      STM32.USARTs.Set_Baud_Rate( STM32.Device.USART_2, 9_600 );
      STM32.USARTs.Set_Oversampling_Mode( STM32.Device.USART_2, STM32.USARTs.Oversampling_By_16 );
      STM32.USARTs.Set_Mode( STM32.Device.USART_2, STM32.USARTs.Tx_Rx_Mode );
      STM32.USARTs.Set_Flow_Control( STM32.Device.USART_2, STM32.USARTs.No_Flow_Control );
      
      
      -- UART 3
      STM32.USARTs.Enable( STM32.Device.USART_3 );
      STM32.USARTs.Set_Stop_Bits( STM32.Device.USART_3, STM32.USARTs.Stopbits_1 );
      STM32.USARTs.Set_Word_Length( STM32.Device.USART_3, STM32.USARTs.Word_Length_8 );
      STM32.USARTs.Set_Parity( STM32.Device.USART_3, STM32.USARTs.No_Parity );
      STM32.USARTs.Set_Baud_Rate( STM32.Device.USART_3, 9_600 );
      STM32.USARTs.Set_Oversampling_Mode( STM32.Device.USART_3, STM32.USARTs.Oversampling_By_16 );
      STM32.USARTs.Set_Mode( STM32.Device.USART_3, STM32.USARTs.Tx_Rx_Mode );
      STM32.USARTs.Set_Flow_Control( STM32.Device.USART_3, STM32.USARTs.No_Flow_Control );


      -- UART 7 (SER 5)
      STM32.USARTs.Enable( STM32.Device.USART_7 );
      STM32.USARTs.Set_Stop_Bits( STM32.Device.USART_7, STM32.USARTs.Stopbits_1 );
      STM32.USARTs.Set_Word_Length( STM32.Device.USART_7, STM32.USARTs.Word_Length_8 );
      STM32.USARTs.Set_Parity( STM32.Device.USART_7, STM32.USARTs.No_Parity );
      STM32.USARTs.Set_Baud_Rate( STM32.Device.USART_7, 9_600 );
      STM32.USARTs.Set_Oversampling_Mode( STM32.Device.USART_7, STM32.USARTs.Oversampling_By_8 );
      STM32.USARTs.Set_Mode( STM32.Device.USART_7, STM32.USARTs.Tx_Rx_Mode );
      STM32.USARTs.Set_Flow_Control( STM32.Device.USART_7, STM32.USARTs.No_Flow_Control );

   end configure;
      

   function map ( Device : in Device_ID_Type ) return STM32.USARTs.USART is
     (case (Device) is
	 when GPS => STM32.Device.USART_1,
	 when Console => STM32.Device.USART_3 );
   
   
   procedure write (Device : in Device_ID_Type; Data : in Data_Type) is
      i : Natural := 0;
      dev : STM32.USARTs.USART := map (Device);
   begin
      for i in Data'Range loop
	 STM32.USARTs.Transmit( dev, HAL.Uint9( Data(i) ) );
      end loop;
   end write;
   

   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is
      i : Natural := 0;
   begin
      for i in Data'Range loop
	 STM32.USARTs.Receive( map(Device), HAL.Uint9( Data(i) ) );
      end loop;
   end read;
   

   function toData_Type( Message : String ) return Data_Type is
   begin
      return (1 => 0);
   end toData_Type;

			     
end HIL.UART;
