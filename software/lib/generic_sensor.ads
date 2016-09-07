-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors:     Emanuel Regnath (emanuel.regnath@tum.de)
--              Martin Becker (becker@rcs.ei.tum.de)

--  with Ada.Real_Time;
with Generic_Signal;

--  those are required for LSP
--  with MS5611.Driver;
--  with ublox8.Driver;
--  with MPU6000.Driver;
--  with HMC5883L.Driver;

--  @summary Generic sensor template. No dispatching here!
--  FIXME: for the sake of polymorphism, dispatching should
--  be added some day.
generic
   type Data_Type is private; 
package Generic_Sensor with SPARK_Mode
--,Abstract_State => Sensor_State -- implementations may have a state
is

   package Sensor_Signal is new Generic_Signal( Data_Type );
   subtype Sample_Type is Sensor_Signal.Sample_Type;

   type Sensor_State_Type is (UNINITIALIZED, OFF, READY, MEASURING, NEW_DATA, ERROR) with Default_Value => UNINITIALIZED;
   
   type State_Type is record
      Initialized : Boolean := False;
      Active : Boolean := False;
      Busy   : Boolean := False;
      Error  : Boolean := False;
   end record;
   
   --  null procedures don't make sense here. It is legal to not override them,
   --  which makes it pointless defining them in an abstract type.
   --  however, SPARK refuses to specify the Global aspect for abstract procedures,
   --  unlike for null procedures. So we go for null again...

   type Sensor_Tag is abstract tagged record
      state  : Sensor_State_Type; -- to be set by sensor
      sample : Sample_Type; -- sensor-specific, most recent measurement
   end record;

   --procedure initialize(Self : in out Sensor_Tag) is abstract;
   --with Global => (Output => Sensor_State);
--       with Global => (Output => MS5611.Driver.Coefficients,
--                             In_Out => ( 
--                                        Ada.Real_Time.Clock_Time,
--                                        MS5611.Driver.State, ublox8.Driver.State, MPU6000.Driver.State, HMC5883L.Driver.State));
--          
   --  trigger start of the measurement
   --procedure start_Measurement(Self : in out Sensor_Tag) is abstract;
        
   --  read the result from the sensor, possibly includes some pre-processing
   --procedure read_Measurement(Self : in out Sensor_Tag) is abstract;
     --with Global => (In_Out => Sensor_State);
     -- with Global => (In_Out => (MS5611.Driver.State, MS5611.Driver.Coefficients, MPU6000.Driver.State, ublox8.Driver.State, HMC5883L.Driver.State));
        
   -- procedure tick(Self : in out Sensor_Tag) is abstract; -- !!NULL!!
   --  update state, wait for finished conversion
        
   function new_Sample(Self : in Sensor_Tag) return Boolean is 
     ( Self.state = NEW_DATA );
   --  check whether we have a new sample

   function get_Sample(Self : in Sensor_Tag) return Sample_Type is
     ( Self.sample );
   --  get new sample
        
        --function get_State(Self : Sensor_Tag) return Sensor_State_Type;

end Generic_Sensor;
