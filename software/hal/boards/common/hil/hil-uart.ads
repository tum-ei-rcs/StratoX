-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with HIL.Devices;

--  @summary
--  Target-independent specification for HIL of UART
package HIL.UART with
   Spark_Mode => Off
is
   BUFFER_MAX : constant := 200;

   subtype Device_ID_Type is HIL.Devices.Device_Type_UART;

   type Baudrates_Type is range 9_600 .. 1_500_000
   with Static_Predicate => Baudrates_Type in 9_600 | 19_200 | 38_400 | 57_600 | 115_200 | 1_500_000;

   subtype Data_Type is Byte_Array;

   procedure configure;

   procedure write (Device : in Device_ID_Type; Data : in Data_Type);

   procedure read (Device : in Device_ID_Type; Data : out Data_Type);

   function toData_Type (Message : String) return Data_Type;


end HIL.UART;
