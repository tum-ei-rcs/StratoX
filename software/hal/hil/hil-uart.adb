

with STM32.USARTs;
with STM32.Device;

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

      -- UART 6 (PX4IO)
      STM32.USARTs.Enable( STM32.Device.USART_6 );
      STM32.USARTs.Set_Stop_Bits( STM32.Device.USART_6, STM32.USARTs.Stopbits_1 );
      STM32.USARTs.Set_Word_Length( STM32.Device.USART_6, STM32.USARTs.Word_Length_8 );
      STM32.USARTs.Set_Parity( STM32.Device.USART_6, STM32.USARTs.No_Parity );
      STM32.USARTs.Set_Baud_Rate( STM32.Device.USART_6, 1_500_000 );
      STM32.USARTs.Set_Oversampling_Mode( STM32.Device.USART_6, STM32.USARTs.Oversampling_By_16 );
      STM32.USARTs.Set_Mode( STM32.Device.USART_6, STM32.USARTs.Tx_Rx_Mode );
      STM32.USARTs.Set_Flow_Control( STM32.Device.USART_6, STM32.USARTs.No_Flow_Control );
      
      
      -- UART 3 (Serial 2)
      STM32.USARTs.Enable( STM32.Device.USART_3 );
      STM32.USARTs.Set_Stop_Bits( STM32.Device.USART_3, STM32.USARTs.Stopbits_1 );
      STM32.USARTs.Set_Word_Length( STM32.Device.USART_3, STM32.USARTs.Word_Length_8 );
      STM32.USARTs.Set_Parity( STM32.Device.USART_3, STM32.USARTs.No_Parity );
      STM32.USARTs.Set_Baud_Rate( STM32.Device.USART_3, 1_500_000 );
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
      

   procedure write (Device : in Device_ID_Type; Data : in Data_Type) is
   begin
      case (Device) is
      when GPS =>
         for i in Data'Range loop
            STM32.USARTs.Transmit( STM32.Device.USART_1, HAL.Uint9( Data(i) ) );
         end loop;
      when Console =>
         for i in Data'Range loop
            STM32.USARTs.Transmit( STM32.Device.USART_3, HAL.Uint9( Data(i) ) );
         end loop; 
      when PX4IO =>
         for i in Data'Range loop
            STM32.USARTs.Transmit( STM32.Device.USART_7, HAL.Uint9( Data(i) ) );
         end loop; 
      end case;
   end write;


   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is
   begin
      case (Device) is
      when GPS =>
         for i in Data'Range loop
            STM32.USARTs.Receive( STM32.Device.USART_1, HAL.Uint9( Data(i) ) );
         end loop;
      when Console =>
         for i in Data'Range loop
            STM32.USARTs.Receive( STM32.Device.USART_3, HAL.Uint9( Data(i) ) );
         end loop; 
      when PX4IO =>
         for i in Data'Range loop
            STM32.USARTs.Receive( STM32.Device.USART_6, HAL.Uint9( Data(i) ) );
         end loop;       
      end case;
   end read;
   

   function toData_Type( Message : String ) return Data_Type is
   begin
      return (1 => 0);
   end toData_Type;

			     
end HIL.UART;
