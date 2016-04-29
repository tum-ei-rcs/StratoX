


with Bit_Types;

package HAL.I2C is
   pragma Preelaborate;


   type Mode_Type is (MASTER, SLAVE);
   type Speed_Type is (SLOW, FAST);

   type Configuration_Type is record
      Mode  : Mode_Type;
      Speed : Speed_Type;
   end record

   type Data_Type is array(Natural range <>) of Byte;
   
   type Port_Type is (UNKNOWN, I2C1, I2C2);
   type Address_Type is Bits_10;

   type I2C_Device_Type is record
      Port    : Port_Type;
      Address : Address_Type
   end record;

   procedure initialize(Port : in Port_Type; Configuration : in Configuration_Type);

   -- writes data to tx buffer
   procedure write (Device : in I2C_Device_Type; Data : in Data_Type);

   -- reads data from the TX Buffer
   procedure read (Device : in I2C_Device_Type; Data : out Data_Type);

   -- writes and reads data
   procedure transfer (Device : in I2C_Device_Type; Data_TX : in Data_Type; Data_RX : out Data_Type);

end HAL.I2C;
