
-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Driver for the HMC5883L

with Interfaces; use Interfaces;


package HMC5883L.Driver is

   procedure initialize;


   function testConnection return Boolean;

   -- CONFIG_A register
   function getSampleAveraging return Unsigned_8;
   procedure setSampleAveraging(averaging : Unsigned_8);
   function getDataRate return Unsigned_8;
   procedure setDataRate(rate : Unsigned_8);
   function getMeasurementBias return Unsigned_8;
   procedure setMeasurementBias(bias : Unsigned_8);

   -- CONFIG_B register
   function getGain return Unsigned_8;
   procedure setGain(gain : Unsigned_8);

   -- MODE register
   function getMode return Unsigned_8;
   procedure setMode(mode : Unsigned_8);

   -- DATA* registers
   procedure getHeading(Integer_16 *x; Integer_16 *y; Integer_16 *z);
   function getHeadingX return Integer_16;
   function getHeadingY return Integer_16;
   function getHeadingZ return Integer_16;

   -- STATUS register
   function getLockStatus return Boolean;
   function getReadyStatus return Boolean;

   -- ID* registers
   function getIDA return Unsigned_8;
   function getIDB return Unsigned_8;
   function getIDC return Unsigned_8;

private


   Unsigned_8 buffer(6);
   mode : Unsigned_8;

end HMC5883L.Driver;
