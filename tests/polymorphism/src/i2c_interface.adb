

package body I2C_Interface with SPARK_Mode
  --,Refined_State => (State => (G_Data)) 
is


   G_Data : Data_Type(1 .. 2);
   
   procedure configure(Port : I2C_Type; Config : Configuration_Type) is
   begin
      -- Port.pin = 0;
      null;
   end configure;

   procedure write (Port : I2C_Type; Address : Address_Type; Data : Data_Type) is
   begin
      G_Data(1) := Data(1);
   end write;

   function read (Port : I2C_Type; Address : Address_Type) return Data_Type is
   begin
      return G_Data;
   end read;

end I2C_Interface;
