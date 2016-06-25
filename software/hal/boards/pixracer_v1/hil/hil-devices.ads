-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Software Configuration
--
-- Authors: Martin Becker (becker@rcs.ei.tum.de)
with FM25v02.Driver;

--  @summary
--  Target-specific types for the devices that are exposed
--  in hil-i2c et. al in Pixracer V1.
package HIL.Devices with SPARK_Mode is
   type Device_Type_I2C is (UNKNOWN);
   type Device_Type_SPI is (Barometer,
                            FRAM);
   type Device_Type_UART is (Console);
   type Device_Type_GPIO is (RED_LED,
                             GRN_LED,
                             BLU_LED,
                             SPI_CS_BARO,
                             SPI_CS_FRAM);

   subtype NVRAM_Address is FM25v02.Driver.Address;
end HIL.Devices;
