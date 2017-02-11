-- Project: MART - Modular Airborne Real-Time Testbed
-- System:  Emergency Recovery System
-- Authors: Markus Neumair (Original C-Code)
--          Emanuel Regnath (emanuel.regnath@tum.de) (Ada Port)
--
-- Module Description:

-- @summary Top-level driver for the Barometer MS5611-01BA03
package MS5611 with SPARK_Mode is

   -- define return values
   type Sample_Status_Type is
     (BARO_NO_NEW_VALUE,
      BARO_NEW_TEMPERATURE,
      BARO_NEW_PRESSURE,
      BARO_READ_TEMPERATURE_ERROR,
      BARO_READ_PRESSURE_ERROR);

end MS5611;
