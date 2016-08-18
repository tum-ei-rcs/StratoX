-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Software Configuration
--
-- Authors: Martin Becker (becker@rcs.ei.tum.de)

--  @summary
--  Target-specific types for the devices that are exposed
--  in hil-i2c et. al in Pixracer V1.
package HIL.Devices with SPARK_Mode is

   type Device_Type_I2C is (UNKNOWN);
   type Device_Type_SPI is (Barometer,
                            FRAM);
   type Device_Type_UART is (CONSOLE);
   type Device_Type_GPIO is (RED_LED,
                             GRN_LED,
                             BLU_LED,
                             SPI_CS_BARO,
                             SPI_CS_FRAM);

   subtype Device_Type_LED is Device_Type_GPIO range RED_LED .. BLU_LED;

   -- INTERRUPT PRIOS, ALL AT ONE PLACE. Must decide who wins here.
   --IRQ_PRIO_UART_LOG : constant := 251; -- if this is too low, we lose input/output
   IRQ_PRIO_SDIO     : constant := 250; -- sdcard: only affects performance (=DMA finish/Start signaling)
end HIL.Devices;
