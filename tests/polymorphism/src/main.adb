--with Generic_Sensor; use Generic_Sensor
with I2C_Interface; with I2C_Interface;
with HAL_Interface; with HAL_Interface;

procedure main with SPARK_Mode is

   I2C : I2C_Interface.I2C_Type;

   data : HAL_Interface.Data_Type(1 ..2) := (others => 0);

begin



   I2C.write(17, data);

end main;


