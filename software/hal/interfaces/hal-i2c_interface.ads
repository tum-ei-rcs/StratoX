package HAL.I2C_Interface is
   pragma Preelaborate;

   type Port_Type is limited interface;

   -- type I2C_Configuration is abstract;

   type Address_Type is Uint10;
   type Data_Type is array(Natural range <>) of Byte;
   

   procedure write (Port : Port_Type; Address : Address_Type; Data : Data_Type) is abstract;

   function read (Port : Port_Type; Address : Address_Type) return Data_Type is abstract;

end HAL.I2C_Interface;
