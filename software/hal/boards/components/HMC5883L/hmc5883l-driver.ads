
-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Driver for the HMC5883L

with Interfaces; use Interfaces;


package HMC5883L.Driver with
SPARK_Mode,
  Abstract_State => State,
    Initializes => State
is

   procedure initialize;


   function testConnection return Boolean;

   -- CONFIG_A register
   function getSampleAveraging return Unsigned_8;
   procedure setSampleAveraging(averaging : Unsigned_8);
   procedure getDataRate(rate : out Unsigned_8);
   procedure setDataRate(rate : Unsigned_8);
   procedure getMeasurementBias(bias : out Unsigned_8);
   procedure setMeasurementBias(bias : Unsigned_8);

   -- CONFIG_B register
   procedure getGain(gain : out Unsigned_8);
   procedure setGain(gain : Unsigned_8);

   -- MODE register
   procedure getMode(mode : out Unsigned_8);
   procedure setMode(newMode : Unsigned_8);

   -- DATA* registers
   procedure getHeading(x : out Integer_16; y : out Integer_16; z : out Integer_16);
   procedure getHeadingX(x : out Integer_16);
   procedure getHeadingY(y : out Integer_16);
   procedure getHeadingZ(z : out Integer_16);

   -- STATUS register
   function getLockStatus return Boolean;
   function getReadyStatus return Boolean;

   -- ID* registers
   function getIDA return Unsigned_8;
   function getIDB return Unsigned_8;
   function getIDC return Unsigned_8;

private

   type Buffer_Type is array( 1 .. 6 ) of Unsigned_8;

   buffer : Buffer_Type with Part_Of => State;
   mode : Unsigned_8 with Part_Of => State;

end HMC5883L.Driver;
