


with Bit_Types;

package HIL.I2C is
   pragma Preelaborate;


   type Port_Type is (UNKNOWN, I2C1, I2C2);

   type Address_Type is Bits_10;
   type Data_Type is array(Natural range <>) of Byte;
   
   type Device_Type is record
   	Port    : Port_Type;
   	Address : Address_Type
   	end record;

   procedure initialize;


   procedure write (Port : Port_Type; Address : Address_Type; Data : Data_Type);

   function read (Port : Port_Type; Address : Address_Type) return Data_Type;


end HIL.I2C;
