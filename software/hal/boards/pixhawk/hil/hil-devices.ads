-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Software Configuration
--
-- Authors: Martin Becker (becker@rcs.ei.tum.de)

--  @summary
--  Target-specific types for the devices that are exposed
--  in hil-i2c et. al in Pixhawk.
package HIL.Devices with SPARK_Mode is
   type Device_Type_I2C is (UNKNOWN, MAGNETOMETER);
   type Device_Type_SPI is (Barometer, Magneto, MPU6000, FRAM, Extern);
   type Device_Type_UART is (GPS, Console, PX4IO);
   type Device_Type_GPIO is (RED_LED,
                            SPI_CS_BARO,
                            SPI_CS_MPU6000,
                            SPI_CS_LSM303D,
                            SPI_CS_L3GD20H,
                            SPI_CS_FRAM,
                            SPI_CS_EXT
                            );

   -- INTERRUPT PRIOS, ALL AT ONE PLACE. Must decide who wins here.
   IRQ_PRIO_UART4    : constant := 251; -- must be higher, because too low could result in loss of data
   IRQ_PRIO_UART_LOG : constant := 249;
   IRQ_PRIO_SDIO     : constant := 250; -- sdcard: can be lower. only affects throughput, not data integrity.


end HIL.Devices;
