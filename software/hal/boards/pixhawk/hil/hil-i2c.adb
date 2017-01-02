--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)

with STM32.I2C;
with STM32.Device;
with HAL.I2C;

with HMC5883L.Register;
with Interfaces.Bit_Types; use Interfaces.Bit_Types;

--  @summary
--  Target-specific mapping for HIL of I2C
package body HIL.I2C with
   SPARK_Mode => Off
is

   ADDR_HMC5883L :constant  HAL.I2C.I2C_Address := HMC5883L.Register.HMC5883L_ADDRESS;

   procedure initialize is
      Config : constant STM32.I2C.I2C_Configuration := (
					       Clock_Speed => 100_000,
                                               Mode => STM32.I2C.I2C_Mode,
                                               Duty_Cycle => STM32.I2C.DutyCycle_2,
					       Addressing_Mode => STM32.I2C.Addressing_Mode_7bit,
					       Own_Address => 16#00#,
                                               General_Call_Enabled => False,
                                               Clock_Stretching_Enabled => False
					       );				       
   begin
      STM32.Device.Reset(STM32.Device.I2C_1);
      STM32.I2C.Configure(STM32.Device.I2C_1, Config);
      -- is_Init := True;
   end initialize;

   procedure write (Device : in Device_Type; Data : in Data_Type) is
      Status : HAL.I2C.I2C_Status;
   begin
      case (Device) is
      when UNKNOWN => null;
      when MAGNETOMETER => 
         STM32.I2C.Master_Transmit(STM32.Device.I2C_1, ADDR_HMC5883L, HAL.I2C.I2C_Data( Data ), Status);
      end case;
   end write;
   
   procedure read (Device : in Device_Type; Data : out Data_Type) is
      Data_RX_I2C : HAL.I2C.I2C_Data(1 .. Data'Length);
      Status : HAL.I2C.I2C_Status;
   begin
      case (Device) is
      when UNKNOWN => null;
      when MAGNETOMETER => 
         STM32.I2C.Master_Receive(STM32.Device.I2C_1, ADDR_HMC5883L, Data_RX_I2C, Status);      
         Data := Data_Type( Data_RX_I2C);
      end case;
   end read;
   

   procedure transfer (Device : in Device_Type; Data_TX : in Data_Type; Data_RX : out Data_Type) is
      Data_RX_I2C : HAL.I2C.I2C_Data(1 .. Data_RX'Length);
      Status : HAL.I2C.I2C_Status;
   begin
      case (Device) is
      when UNKNOWN => null;
      when MAGNETOMETER => 
         STM32.I2C.Mem_Read(STM32.Device.I2C_1, ADDR_HMC5883L, Short( Data_TX(1) ), HAL.I2C.Memory_Size_8b, Data_RX_I2C, Status);
--           STM32.I2C.Master_Transmit(STM32.Device.I2C_1, ADDR_HMC5883L, HAL.I2C.I2C_Data( Data_TX ), Status);
--           STM32.I2C.Master_Receive(STM32.Device.I2C_1, ADDR_HMC5883L, Data_RX_I2C, Status);
         Data_RX := Data_Type( Data_RX_I2C);
      end case;
   end transfer;

end HIL.I2C;
