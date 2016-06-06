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

with Generic_Signal;

generic
   type Data_Type is private; 
package Generic_Sensor with SPARK_Mode is

   package Sensor_Signal is new Generic_Signal( Data_Type );
   type Sample_Type is new Sensor_Signal.Sample_Type;

   type Sensor_State_Type is (UNINITIALIZED, OFF, READY, MEASURING, NEW_DATA, ERROR);
   
   type State_Type is record
      Initialized : Boolean := False;
      Active : Boolean;
      Busy   : Boolean;
      Error  : Boolean;
   end record;
   

   type Sensor_Tag is tagged record
      state : Sensor_State_Type := UNINITIALIZED;
      sample  : Sample_Type;
   end record;

   procedure initialize(Self : in out Sensor_Tag) is null;
        
   -- start the measurement
   procedure start_Measurement(Self : in out Sensor_Tag) is null;
        
   -- read the result from the sensor, possible post processing
   procedure read_Measurement(Self : in out Sensor_Tag) is null;
        
   --  update state, wait for finished conversion
   procedure tick(Self : in out Sensor_Tag) is null;

        
   function new_Sample(Self : in out Sensor_Tag) return Boolean is 
           ( Self.state = NEW_DATA );

   function get_Sample(Self : in out Sensor_Tag) return Sample_Type is
           ( Self.sample );
        
        --function get_State(Self : Sensor_Tag) return Sensor_State_Type;

private

--     type Sensor_Tag is tagged record
--        state : Sensor_State_Type;
--        data  : Data_Type;
--     end record;


end Generic_Sensor;
