--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
pragma SPARK_Mode (Off);

with STM32.USARTs;
with STM32.Device;
with HIL.Config;

with Ada.Interrupts;       use Ada.Interrupts;
with Ada.Interrupts.Names; use Ada.Interrupts.Names;

with Generic_Queue; 
with HIL.Devices;

--  @summary
--  Target-specific mapping for HIL of UART
package body HIL.UART with
   SPARK_Mode => Off
is  
   
   procedure configure with SPARK_Mode => Off is 
   begin
      --  For Adaracer_1.1, the CLI port is connected to UART7, and
      --  UART4 isn't connected to anything.
--        STM32.USARTs.Enable (STM32.Device.UART_7);
--        STM32.USARTs.Set_Stop_Bits (STM32.Device.UART_7, STM32.USARTs.Stopbits_1);
--        STM32.USARTs.Set_Word_Length (STM32.Device.UART_7, STM32.USARTs.Word_Length_8);
--        STM32.USARTs.Set_Parity (STM32.Device.UART_7, STM32.USARTs.No_Parity);
--        STM32.USARTs.Set_Baud_Rate (STM32.Device.UART_7, 115_200);
--        STM32.USARTs.Set_Oversampling_Mode (STM32.Device.UART_7, STM32.USARTs.Oversampling_By_16);
--        STM32.USARTs.Set_Mode (STM32.Device.UART_7, STM32.USARTs.Tx_Rx_Mode);
--        STM32.USARTs.Set_Flow_Control (STM32.Device.UART_7, STM32.USARTs.No_Flow_Control);
      STM32.USARTs.Enable( STM32.Device.USART_7 );
      STM32.USARTs.Set_Stop_Bits( STM32.Device.USART_7, STM32.USARTs.Stopbits_1 );
      STM32.USARTs.Set_Word_Length( STM32.Device.USART_7, STM32.USARTs.Word_Length_8 );
      STM32.USARTs.Set_Parity( STM32.Device.USART_7, STM32.USARTs.No_Parity );
      STM32.USARTs.Set_Baud_Rate( STM32.Device.USART_7, 115_200 );
      STM32.USARTs.Set_Oversampling_Mode( STM32.Device.USART_7, STM32.USARTs.Oversampling_By_8 );
      STM32.USARTs.Set_Mode( STM32.Device.USART_7, STM32.USARTs.Tx_Rx_Mode );
      STM32.USARTs.Set_Flow_Control( STM32.Device.USART_7, STM32.USARTs.No_Flow_Control );
      
      -- UART 1
      -- STM32.USARTs.Enable( STM32.Device.USART_1 );
      STM32.USARTs.Set_Stop_Bits( STM32.Device.USART_1, STM32.USARTs.Stopbits_1 );
      STM32.USARTs.Set_Word_Length( STM32.Device.USART_1, STM32.USARTs.Word_Length_8 );
      STM32.USARTs.Set_Parity( STM32.Device.USART_1, STM32.USARTs.No_Parity );
      STM32.USARTs.Set_Baud_Rate( STM32.Device.USART_1, 9_600 );
      STM32.USARTs.Set_Oversampling_Mode( STM32.Device.USART_1, STM32.USARTs.Oversampling_By_16 );
      STM32.USARTs.Set_Mode( STM32.Device.USART_1, STM32.USARTs.Tx_Rx_Mode );
      STM32.USARTs.Set_Flow_Control( STM32.Device.USART_1, STM32.USARTs.No_Flow_Control );
      
      -- UART 3 (Serial 2, Tele 2, Console)
      STM32.USARTs.Enable( STM32.Device.USART_3 );
      STM32.USARTs.Set_Stop_Bits( STM32.Device.USART_3, STM32.USARTs.Stopbits_1 );
      STM32.USARTs.Set_Word_Length( STM32.Device.USART_3, STM32.USARTs.Word_Length_8 );
      STM32.USARTs.Set_Parity( STM32.Device.USART_3, STM32.USARTs.No_Parity );
      STM32.USARTs.Set_Baud_Rate( STM32.Device.USART_3, 57_600 );
      STM32.USARTs.Set_Oversampling_Mode( STM32.Device.USART_3, STM32.USARTs.Oversampling_By_16 );
      STM32.USARTs.Set_Mode( STM32.Device.USART_3, STM32.USARTs.Tx_Rx_Mode );
      STM32.USARTs.Set_Flow_Control( STM32.Device.USART_3, STM32.USARTs.No_Flow_Control );
           
      -- Interrupts
      -- Enable GPS Interrupt
      -- STM32.USARTs.Enable_Interrupts( STM32.Device.UART_4, STM32.USARTs.Received_Data_Not_Empty );
      
      -- Logger Interrupt
      
  
     

   end configure;
      

   --  writes devices by internally mapping to U(S)ART ports
   procedure write (Device : in Device_ID_Type; Data : in Data_Type) is
      procedure write_to_port (port : in out STM32.USARTs.USART; Data : in Data_Type);
      procedure write_to_port (port : in out STM32.USARTs.USART; Data : in Data_Type) is
         flag : constant STM32.USARTs.USART_Status_Flag := STM32.USARTs.USART_Status_Flag'First;
         ret : constant Boolean := STM32.USARTs.Status (port, flag);
      begin
         for i in Data'Range loop
            while not STM32.USARTs.Tx_Ready (port) loop
               null;
            end loop;
            STM32.USARTs.Transmit (port, HAL.UInt9 (Data (i)));
         end loop;
      end write_to_port;
   begin
      case (Device) is
      when CONSOLE =>
         write_to_port (STM32.Device.USART_7, Data);
--        when TELE1 =>
--           write_to_port (STM32.Device.USART_2, Data);
--        when TELE2 =>
--           write_to_port (STM32.Device.USART_3, Data);
--        when WIFI =>
--           write_to_port (STM32.Device.USART_1, Data);
--        when GPS =>
--           write_to_port (STM32.Device.UART_4, Data);
      end case;
   end write;

   --  reads devices by internally mapping to U(S)ART ports
   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is
      procedure read_from_port (port : in out STM32.USARTs.USART; Data : out Data_Type);
      procedure read_from_port (port : in out STM32.USARTs.USART; Data : out Data_Type) is
      begin
         for i in Data'Range loop
            STM32.USARTs.Receive (port, HAL.UInt9 (Data (i)));
         end loop;
      end read_from_port;
   begin
      case (Device) is
      when CONSOLE =>
         read_from_port (STM32.Device.USART_7, Data);
--        when TELE1 =>
--           read_from_port (STM32.Device.USART_2, Data);
--        when TELE2 =>
--           read_from_port (STM32.Device.USART_3, Data);
--        when WIFI =>
--           read_from_port (STM32.Device.USART_1, Data);
--        when GPS =>
--           read_from_port (STM32.Device.UART_4, Data);
      end case;
   end read;

   function toData_Type (Message : String) return Data_Type is
      Bytes : Data_Type (Message'Range) := (others => 0);
   begin
      for pos in Message'Range loop
         Bytes (pos) := Character'Pos (Message (pos));
      end loop;
      return Bytes;
   end toData_Type;


end HIL.UART;
