

with STM32.I2C;
with STM32.Device;
with HAL.I2C;

with HMC5883L.Register;

package body HIL.I2C with
   SPARK_Mode => Off
is

   ADDR_HMC5883L : HAL.I2C.I2C_Address := HMC5883L.Register.HMC5883L_ADDRESS;

   procedure initialize is
      Config : constant STM32.I2C.I2C_Configuration := (
					       Clock_Speed => 44,
                                               Mode => STM32.I2C.I2C_Mode,
                                               Duty_Cycle => STM32.I2C.DutyCycle_2,
					       Addressing_Mode => STM32.I2C.Addressing_Mode_7bit,
					       Own_Address => 16#00#,
                                               General_Call_Enabled => False,
                                               Clock_Stretching_Enabled => True
					       );				       
   begin
   	STM32.I2C.Configure(STM32.Device.I2C_1, Config);
   end initialize;

   procedure write (Device : in Device_Type; Data : in Data_Type) is
      Status : HAL.I2C.I2C_Status;
   begin
      case (Device) is
      when UNKNOWN => null;
      when HMC5883L => 
         STM32.I2C.Master_Transmit(STM32.Device.I2C_1, ADDR_HMC5883L, Data, Status);
      end case;
   end write;
   
   procedure read (Device : in Device_Type; Data : out Data_Type) is
   begin
      null;
   end read;
   

   procedure transfer (Device : in Device_Type; Data_TX : in Data_Type; Data_RX : in Data_Type) is
   begin
      case (Device) is
      when UNKNOWN => null;
      when HMC5883L => 
         STM32.I2C.Master_Transmit(STM32.Device.I2C_1, ADDR_HMC5883L, Data_TX, Status);
         STM32.I2C.Master_Receive(STM32.Device.I2C_1, ADDR_HMC5883L, Data_RX, Status);         
      end case;
   end transfer;

end HIL.I2C;
