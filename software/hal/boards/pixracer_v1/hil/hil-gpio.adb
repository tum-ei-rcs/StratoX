--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with STM32.GPIO;  use STM32.GPIO;
with STM32.Device;
with STM32.Board;

--  @summary
--  target-specific mapping of HIL for GPIO
package body HIL.GPIO with
   SPARK_Mode => Off
is
   subtype Dev_GPIO is  STM32.GPIO.GPIO_Point; -- abbreviate the long name

--     SPI1_SCK        : constant Dev_GPIO := STM32.Device.PA5;
--     SPI1_MISO       : constant Dev_GPIO := STM32.Device.PA6;
--     SPI1_MOSI       : constant Dev_GPIO := STM32.Device.PA7;
--     SPI1_CS_MS5611  : constant Dev_GPIO := STM32.Device.PD7;   -- Baro
--  --     SPI1_CS_MPU6000 : constant Dev_GPIO := STM32.Device.PC2;   -- Acc/Gyro
--  --     SPI1_CS_LSM303D : constant Dev_GPIO := STM32.Device.PC15;  -- Acc/Mag
--  --     SPI1_CS_L3GD20H : constant Dev_GPIO := STM32.Device.PC13;  -- Gyro
--

   --  SPI2: FRAM + BARO
   SPI2_SCK     : constant Dev_GPIO := STM32.Device.PB10; -- OK
   SPI2_MISO    : constant Dev_GPIO := STM32.Device.PB14; -- OK
   SPI2_MOSI    : constant Dev_GPIO := STM32.Device.PB15; -- OK
   SPI2_CS_FRAM : constant Dev_GPIO := STM32.Device.PD10; -- OK
   SPI2_CS_BARO : constant Dev_GPIO := STM32.Device.PD7;  -- OK

   I2C1_SCL : constant Dev_GPIO := STM32.Device.PB8; -- OK
   I2C1_SDA : constant Dev_GPIO := STM32.Device.PB9; -- OK

   UART2_RX : constant Dev_GPIO := STM32.Device.PD6; -- OK
   UART2_TX : constant Dev_GPIO := STM32.Device.PD5; -- OK

   UART3_RX : constant Dev_GPIO := STM32.Device.PD9; -- OK
   UART3_TX : constant Dev_GPIO := STM32.Device.PD8; -- OK

   UART4_RX : constant Dev_GPIO := STM32.Device.PA1; -- OK
   UART4_TX : constant Dev_GPIO := STM32.Device.PA0; -- OK

   Config_SPI1 : constant GPIO_Port_Configuration := (
                                                      Mode => Mode_AF,
                                                      Output_Type => Push_Pull,
                                                      Speed => Speed_50MHz,
                                                      Resistors => Floating );

   Config_SPI2 : constant GPIO_Port_Configuration := (
                                                      Mode => Mode_AF,
                                                      Output_Type => Push_Pull,
                                                      Speed => Speed_50MHz,
                                                      Resistors => Floating );

   Config_I2C1 : constant GPIO_Port_Configuration := (
                                                      Mode => Mode_AF,
                                                      Output_Type => Open_Drain,
                                                      Speed => Speed_25MHz,
                                                      Resistors => Floating );

   Config_UART3 : constant GPIO_Port_Configuration := (
                                                       Mode => Mode_AF,
                                                       Output_Type => Push_Pull,
                                                       Speed => Speed_50MHz,
                                                       Resistors => Floating );

   Config_UART6 : constant GPIO_Port_Configuration := (
                                                       Mode => Mode_AF,
                                                       Output_Type => Push_Pull,
                                                       Speed => Speed_50MHz,
                                                       Resistors => Floating );

   Config_In : constant GPIO_Port_Configuration := (
                                                    Mode => Mode_In,
                                                    Output_Type => Push_Pull,
                                                    Speed => Speed_50MHz,
                                                    Resistors => Floating );


   function map(Point : GPIO_Point_Type) return GPIO_Point is
   ( case Point is
       when RED_LED        => STM32.Board.Red,
       when BLU_LED        => STM32.Board.Blue,
       when GRN_LED        => STM32.Board.Green,
       when SPI_CS_BARO    => SPI2_CS_BARO,
--         when SPI_CS_MPU6000 => SPI1_CS_MPU6000,
--         when SPI_CS_LSM303D => SPI1_CS_LSM303D,
--         when SPI_CS_L3GD20H => SPI1_CS_L3GD20H,
       when SPI_CS_FRAM    => SPI2_CS_FRAM
--         when SPI_CS_EXT     => SPI4_CS
     );


   procedure write (Point : GPIO_Point_Type; Signal : GPIO_Signal_Type) is
      stm32_point : GPIO_Point := map( Point );
   begin
      case (Signal) is
         when LOW  => STM32.GPIO.Clear( stm32_point  );
         when HIGH => STM32.GPIO.Set( stm32_point  );
      end case;
   end write;


   procedure read (Point : GPIO_Point_Type; Signal : out GPIO_Signal_Type) is
      stm32_point : constant GPIO_Point := map( Point );
   begin
      if STM32.GPIO.Set(stm32_point) then
         Signal := HIGH;
      else
         Signal := LOW;
      end if;
   end read;


   procedure configure is
      Config_Out : constant GPIO_Port_Configuration := (
                                                        Mode => Mode_Out,
                                                        Output_Type => Push_Pull,
                                                        Speed => Speed_2MHz,
                                                        Resistors => Floating );
   begin
      -- configure LEDs
      Configure_IO( Points => (1 => map(RED_LED)), Config => Config_Out );
      Configure_IO( Points => (1 => map(BLU_LED)), Config => Config_Out );
      Configure_IO( Points => (1 => map(GRN_LED)), Config => Config_Out );

--        -- configure SPI 1
--        Configure_IO( Points => (SPI1_SCK, SPI1_MISO, SPI1_MOSI), Config => Config_SPI1 );
--        Configure_Alternate_Function(
--                                     Points => (1 => SPI1_SCK, 2 => SPI1_MOSI, 3 => SPI1_MISO),
--                                     AF     => GPIO_AF_SPI1);

      -- configure SPI 2
      Configure_IO( Points => (SPI2_SCK, SPI2_MISO, SPI2_MOSI), Config => Config_SPI2 );
      Configure_Alternate_Function(
                                   Points => (1 => SPI2_SCK, 2 => SPI2_MOSI, 3 => SPI2_MISO),
                                   AF     => GPIO_AF_SPI2);

      -- configure Baro ChipSelect
      Configure_IO( Point => map(SPI_CS_BARO), Config => Config_Out );
      STM32.GPIO.Set( This => map(SPI_CS_BARO) );
--
--  --        -- configure MPU6000 ChipSelect
--  --        Configure_IO( Point => map(SPI_CS_MPU6000), Config => Config_Out );
--  --        Point := map(SPI_CS_MPU6000);
--  --        STM32.GPIO.Set( This => Point );
--  --
--  --        -- configure LSM303D ChipSelect
--  --        Configure_IO( Point => map(SPI_CS_LSM303D), Config => Config_Out );
--  --        Point := map(SPI_CS_LSM303D);
--  --        STM32.GPIO.Set( This => Point );
--  --
--  --        -- configure L3GD20H ChipSelect
--  --        Configure_IO( Point => map(SPI_CS_L3GD20H), Config => Config_Out );
--  --        Point := map(SPI_CS_L3GD20H);
--  --        STM32.GPIO.Set( This => Point );
--
      -- configure FRAM ChipSelect
      Configure_IO( Point => map(SPI_CS_FRAM), Config => Config_Out );
      STM32.GPIO.Set( This => map(SPI_CS_FRAM) );
--
--        --configure SPI 4
--        Configure_IO( Points => (SPI4_SCK, SPI4_MISO, SPI4_MOSI), Config => Config_SPI1 );
--
--        Configure_Alternate_Function(
--                                     Points => (SPI4_SCK, SPI4_MOSI, SPI4_MISO),
--                                     AF     => GPIO_AF_SPI4);
--
--        Configure_IO( Point => SPI4_CS, Config => Config_Out );
--        --Point := map(SPI_CS_EXT);
--        --STM32.GPIO.Set( This => Point );
--
--        -- I2C
--        -- -----------------------------------------------------------------------
--        Configure_Alternate_Function(
--                                     Points => (I2C1_SDA, I2C1_SCL),
--                                     AF     => GPIO_AF_I2C);
--        Configure_IO( Points => (I2C1_SDA, I2C1_SCL), Config => Config_I2C1 );
--
--
--
--        -- UART
--        -- -----------------------------------------------------------------------
--        -- configure UART 2
--        Configure_IO( Points => (UART2_RX, UART2_TX), Config => Config_UART3 );
--
--        Configure_Alternate_Function(
--                                     Points => (UART2_RX, UART2_TX),
--                                     AF     => GPIO_AF_USART2);
--
--        -- configure UART 3 (Serial 2)
--        Configure_IO( Points => (UART3_RX, UART3_TX), Config => Config_UART3 );
--
--        Configure_Alternate_Function(
--                                     Points => (UART3_RX, UART3_TX),
--                                     AF     => GPIO_AF_USART3);
--
--        -- configure UART 4 (Serial 3)
--        Configure_IO( Points => (UART4_RX, UART4_TX), Config => Config_UART3 );
--
--        Configure_Alternate_Function(
--                                     Points => (UART4_RX, UART4_TX),
--                                     AF     => GPIO_AF_USART4);
--
--        -- configure UART 6 (PX4IO)
--        Configure_IO( Points => (UART6_TX, UART6_RX), Config => Config_UART6 );
--        -- Configure_IO( Point => UART6_RX, Config => Config_In );
--
--        Configure_Alternate_Function(
--                                     Points => (UART6_TX, UART6_RX),
--                                     AF     => GPIO_AF_USART6);
--
--        -- configure UART 1 (PX4IO - Debug)
--        Configure_IO( Point => UART1_RX, Config => Config_In );


   end configure;

end HIL.GPIO;
