package HIL.SPI with
     Spark_Mode => Off
     -- Abstract_State => Deselect 
is

   type Device_ID_Type is (Barometer, Magneto, MPU6000, Extern);

   type Data_Type is array (Natural range <>) of Byte;

   procedure configure;

   procedure select_Chip (Device : Device_ID_Type);

   procedure deselect_Chip (Device : Device_ID_Type); 
   -- with Global => (Input => (Deselect));

   procedure write (Device : Device_ID_Type; Data : Data_Type);

   procedure read (Device : in Device_ID_Type; Data : out Data_Type);

   procedure transfer
     (Device  : in     Device_ID_Type;
      Data_TX : in     Data_Type;
      Data_RX :    out Data_Type);

end HIL.SPI;
