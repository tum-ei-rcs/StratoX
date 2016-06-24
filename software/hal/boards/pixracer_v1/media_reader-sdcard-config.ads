-- Institution: Technische Universität München
-- Department:  Real-Time Computer Systems (RCS)
-- Project:     StratoX
-- Authors:     Martin Becker (becker@rcs.ei.tum.de)

with Ada.Interrupts.Names;

with STM32.GPIO;
with STM32.DMA;    use STM32.DMA;
with STM32.Device; use STM32.Device;

with STM32_SVD.SDIO;

-- @summary
--  Mapping of system resources for Pixracer V1
--
--  based on https://raw.githubusercontent.com/AdaCore/Ada_Drivers_Library/
--  master/examples/sdcard/src/stm32f7/device_sd_configuration.ads.

package Media_Reader.SDCard.Config is

   SD_Pins       : constant STM32.GPIO.GPIO_Points :=
     (PC8, PC9, PC10, PC11, PC12, PD2);
   --  manual: 8x data, 1xCK, 1x CMD
   --  PC8=D0, PC9=D1, PC10=D2, PC11=D3, PC12=CK, PD2=CMD

   --SD_Detect_Pin : constant STM32.GPIO.GPIO_Point := PC11;
   --  no card detect pin on pixracer

   --  DMA: DMA2 (Stream 3 or Stream 6) with Channel4
   SD_DMA            : DMA_Controller renames DMA_2;
   SD_DMA_Rx_Channel : constant DMA_Channel_Selector :=
                         Channel_4;
   SD_DMA_Rx_Stream  : constant DMA_Stream_Selector :=
                         Stream_3;
   Rx_IRQ            : Ada.Interrupts.Interrupt_ID renames
                         Ada.Interrupts.Names.DMA2_Stream3_Interrupt;
   SD_DMA_Tx_Channel : constant DMA_Channel_Selector :=
                         Channel_4;
   SD_DMA_Tx_Stream  : constant DMA_Stream_Selector :=
                         Stream_6;
   Tx_IRQ            : Ada.Interrupts.Interrupt_ID renames
                         Ada.Interrupts.Names.DMA2_Stream6_Interrupt;
   SD_Interrupt      : Ada.Interrupts.Interrupt_ID renames
                         Ada.Interrupts.Names.SDIO_Interrupt;
   SD_Device         : STM32_SVD.SDIO.SDIO_Peripheral renames
                         STM32_SVD.SDIO.SDIO_Periph;

   procedure Enable_Clock_Device;
   procedure Reset_Device;

end Media_Reader.SDCard.Config;
