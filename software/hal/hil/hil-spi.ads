

package HIL.SPI is

   type Device_ID_Type is (Baro, Magneto, MPU6000)

   type Data_Type is array(Natural range <>) of Byte;
   
   procedure initialize;

   procedure write (Device : Device_ID_Type; Data : Data_Type);

   procedure read (Device : Device_ID_Type; out Data : Data_Type);


end HIL.SPI;
