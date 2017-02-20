package HAL_Interface with SPARK_Mode is
   pragma Preelaborate;

   type Byte is mod 2**8;
   
   type Port_Type is interface;  -- abstract tagged null record; -- interface

   
   type Configuration_Type is null record;

   subtype Address_Type is Integer;
   type Data_Type is array(Natural range <>) of Byte;
   
   procedure configure(Port : Port_Type; Config : Configuration_Type) is abstract;

   procedure write (Port : Port_Type; Address : Address_Type; Data : Data_Type) is abstract;

   function read (Port : Port_Type; Address : Address_Type) return Data_Type is abstract;

end HAL_Interface;
