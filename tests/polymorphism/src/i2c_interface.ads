
with HAL_Interface; use HAL_Interface;


package I2C_Interface with SPARK_Mode
  --,Abstract_State => State
is

   type I2C_Type is new Port_Type with record
      pin : Integer := 0;
   end record;

   
   overriding
   procedure configure(Port : I2C_Type; Config : Configuration_Type);

   overriding
   procedure write (Port : I2C_Type; Address : Address_Type; Data : Data_Type) 
     ; --with Global => (In_Out => State);

   overriding
   function read (Port : I2C_Type; Address : Address_Type) return Data_Type;

end I2C_Interface;
