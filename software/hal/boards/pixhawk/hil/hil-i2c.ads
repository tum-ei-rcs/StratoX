


package HIL.I2C with SPARK_Mode => On is

   subtype Data_Type is Unsigned_8_Array;
   
   type Device_Type is (UNKNOWN, MAGNETOMETER);

   procedure initialize;

   procedure write (Device : in Device_Type; Data : in Data_Type);

   procedure read (Device : in Device_Type; Data : out Data_Type);

   procedure transfer (Device : in Device_Type; Data_TX : in Data_Type; Data_RX : out Data_Type);

end HIL.I2C;
