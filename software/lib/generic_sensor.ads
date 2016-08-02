-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Generic sensor package
-- 
-- ToDo:
-- [ ] Implementation

with Ada.Real_Time;

with Generic_Signal;


with MS5611.Driver;
with ublox8.Driver;
with MPU6000.Driver;
with HMC5883L.Driver;

generic
   type Data_Type is private; 
package Generic_Sensor with SPARK_Mode is

   package Sensor_Signal is new Generic_Signal( Data_Type );
   subtype Sample_Type is Sensor_Signal.Sample_Type;

   type Sensor_State_Type is (UNINITIALIZED, OFF, READY, MEASURING, NEW_DATA, ERROR) with Default_Value => UNINITIALIZED;
   
   type State_Type is record
      Initialized : Boolean := False;
      Active : Boolean := False;
      Busy   : Boolean := False;
      Error  : Boolean := False;
   end record;
   

   type Sensor_Tag is abstract tagged record
      state : Sensor_State_Type;
      sample  : Sample_Type;
   end record;

   procedure initialize(Self : in out Sensor_Tag) 
   is null with Global => (Output => MS5611.Driver.Coefficients,
                           In_Out => (IMU.State, Ada.Real_Time.Clock_Time,
                                      MS5611.Driver.State, ublox8.Driver.State, MPU6000.Driver.State, HMC5883L.Driver.State));
        
   -- start the measurement
   procedure start_Measurement(Self : in out Sensor_Tag) is null;
        
   -- read the result from the sensor, possible post processing
   procedure read_Measurement(Self : in out Sensor_Tag) is null
   with Global => (In_Out => (MS5611.Driver.State, MS5611.Driver.Coefficients, MPU6000.Driver.State, ublox8.Driver.State, HMC5883L.Driver.State));
        
   --  update state, wait for finished conversion
   procedure tick(Self : in out Sensor_Tag) is null;

        
   function new_Sample(Self : in Sensor_Tag) return Boolean is 
           ( Self.state = NEW_DATA );

   function get_Sample(Self : in Sensor_Tag) return Sample_Type is
           ( Self.sample );
        
        --function get_State(Self : Sensor_Tag) return Sensor_State_Type;

private

--     type Sensor_Tag is tagged record
--        state : Sensor_State_Type;
--        data  : Data_Type;
--     end record;


end Generic_Sensor;
