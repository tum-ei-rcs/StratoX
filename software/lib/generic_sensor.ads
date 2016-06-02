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

   type Sensor_State_Type is (UNINITIALIZED, OFF, READY, MEASURING, ERROR);
   
   type State_Type is record
      Initialized : Boolean;
      Active : Boolean;
      Busy   : Boolean;
      Error  : Boolean;
   end record;
   

   type Sensor_Tag is abstract tagged record
      state : Sensor_State_Type := UNINITIALIZED;
      data  : Sample_Type;
   end record;

	procedure initialize(Self : in out Sensor_Tag) is null;

	procedure get_Data(Self : in out Sensor_Tag; Data : out Sample_Type) is null;
        
        --function get_State(Self : Sensor_Tag) return Sensor_State_Type;

private

--     type Sensor_Tag is tagged record
--        state : Sensor_State_Type;
--        data  : Data_Type;
--     end record;


end Generic_Sensor;
