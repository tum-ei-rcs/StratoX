-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with HIL.Devices;

--  @summary
--  Target-independent specification for HIL of I2C
package HIL.UART with
   Spark_Mode
is

   type Device_ID_Type is new HIL.Devices.Device_Type_UART;

   type Baudrates_Type is range 9_600 .. 1_500_000
   with Static_Predicate => Baudrates_Type in 9600 | 38_400 | 1_500_000;

   subtype Data_Type is Byte_Array;

   procedure configure;

   procedure write (Device : in Device_ID_Type; Data : in Data_Type);

   procedure read (Device : in Device_ID_Type; Data : out Data_Type);

   function toData_Type (Message : String) return Data_Type;

end HIL.UART;
