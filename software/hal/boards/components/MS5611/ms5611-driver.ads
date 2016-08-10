--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--           Martin Becker (becker@rcs.ei.tum.de)
with Units;

--  @summary Driver for the Barometer MS5611-01BA03
package MS5611.Driver with
  SPARK_Mode,
  Abstract_State => (State, Coefficients),
  Initializes => (State, Coefficients) -- all have defaults in the body
is

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
   ) with Default_Value => OSR_256;

   procedure Reset;
   --  send a soft-reset to the device.

   procedure Init;
   --  initialize the device, get chip-specific compensation values

   procedure Update_Val;
   --  trigger measurement update. Should be called periodically.

   function Get_Temperature return Temperature_Type;
   -- get temperature from buffer
   -- @return the last known temperature measurement

   function Get_Pressure return Pressure_Type;
   -- get barometric pressure from buffer
   -- @return the last known pressure measurement

   procedure Self_Check (Status : out Error_Type);
   -- implements the self-check of the barometer.
   -- It checks the measured altitude for validity by
   -- comparing them to altitude_offset. Furthermore it can adapt
   -- the takeoff altitude.
   -- @param Status returns the result of self check

end MS5611.Driver;
