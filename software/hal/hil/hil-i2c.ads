


package HIL.I2C is

   type Data_Type is array(Natural range <>) of Byte;
   
   type Device_Type is (UNKNOWN, BARO);

   procedure initialize;

   procedure write (Device : in Device_Type; Data : in Data_Type);

   procedure read (Device : in Device_Type; Data : out Data_Type);

   procedure transfer (Device : in Device_Type; Data_TX : in Data_Type; Data_RX : in Data_Type);

end HIL.I2C;
