


with Bit_Types;

package HIL.SPI is
   pragma Preelaborate;


   type Port_Type is (SPI1, SPI2);

   type Address_Type is Bits_10;
   type Data_Type is array(Natural range <>) of Byte;
   

   procedure initialize;

   procedure write (Port : Port_Type; Address : Address_Type; Data : Data_Type);

   function read (Port : Port_Type; Address : Address_Type) return Data_Type;


end HIL.SPI;
