--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with HIL.Devices;

--  @summary
--  Target-independent specification for HIL of I2C
package HIL.I2C with SPARK_Mode => On is

   subtype Data_Type is Unsigned_8_Array;
         
   type Device_Type is new HIL.Devices.Device_Type_I2C;

   procedure initialize;

   procedure write (Device : in Device_Type; Data : in Data_Type);

   procedure read (Device : in Device_Type; Data : out Data_Type);

   procedure transfer (Device : in Device_Type; Data_TX : in Data_Type; Data_RX : out Data_Type);

end HIL.I2C;
