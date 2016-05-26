-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with Units;

-- @summary
-- Driver for the Barometer MS5611-01BA03
--
-- ToDo:
--  - Adjustment to current System
--  - Use HIL.I2C
package MS5611.Driver with SPARK_Mode is

   type Device_Type is (Baro, NONE);

   type Error_Type is (SUCCESS, FAILURE);

   subtype Time_Type is Units.Time_Type;

   subtype Temperature_Type is
     Units.Temperature_Type range 233.15 .. 358.15;  -- (-)40 .. 85degC, limits from datasheet
   subtype Pressure_Type is
     Units.Pressure_Type range 1000.0 .. 120000.0;   -- 10 .. 1200 mbar, limits from datasheet

   -- this influences the measurement noise/precision and conversion time
   type OSR_Type is (
                     OSR_256, -- 0.012degC/0.065mbar, <0.6ms
                     OSR_512,
                     OSR_1024,
                     OSR_2048,
                     OSR_4096 -- 0.002degC/0.012mbar, <9.04ms
   );

   procedure reset;
   -- send a soft-reset to the device.

   procedure init;
   -- initialize the device, get chip-specific compensation values

   procedure update_val;
   -- trigger measurement update. Should be called periodically.

   function get_temperature return Temperature_Type;
   -- get temperature from buffer
   -- @return the last known temperature measurement

   function get_pressure return Pressure_Type;
   -- get barometric pressure from buffer
   -- @return the last known pressure measurement

   procedure self_check (Status : out Error_Type);
   -- implements the self-check of the barometer.
   -- It checks the measured altitude for validity by
   -- comparing them to altitude_offset. Furthermore it can adapt
   -- the takeoff altitude.
   -- @param Status returns the result of self check

end MS5611.Driver;
