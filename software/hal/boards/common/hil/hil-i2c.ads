--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with HIL.Devices;

--  @summary
--  Target-independent specification for HIL of I2C
package HIL.I2C with SPARK_Mode => On is

   
--     type Port_Type is limited interface;
--  
--     type Configuration_Type is null record;
--     
--     procedure configure(Port : Port_Type; Config : Configuration_Type) is abstract;
--    
   
   
   
   subtype Data_Type is Unsigned_8_Array;
         
   type Device_Type is new HIL.Devices.Device_Type_I2C;
   
   is_Init : Boolean := False with Ghost;

   procedure initialize with 
     Pre => is_Init = False, 
     Post => is_Init = True;

   procedure write (Device : in Device_Type; Data : in Data_Type) with 
     Pre => is_Init = True;

   procedure read (Device : in Device_Type; Data : out Data_Type) with 
     Pre => is_Init = True;

   procedure transfer (Device : in Device_Type; Data_TX : in Data_Type; Data_RX : out Data_Type) with 
     Pre => is_Init = True;

 
end HIL.I2C;
