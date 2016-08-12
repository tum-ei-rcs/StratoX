with Simulation;
with Ada.Text_IO; use Ada.Text_IO;

package body MPU6000.Driver  with
Refined_State => (State => (Is_Init, Device_Address))
is

   procedure Init is null;

   --  Test if the MPU6000 is initialized and connected.
   function Test return Boolean is (True);

   --  Test if we are connected to MPU6000 via I2C.
   function Test_Connection return Boolean is (True);

   --  MPU6000 self test.
   function Self_Test return Boolean is (True);

   --  Reset the MPU6000 device.
   --  A small delay of ~50ms may be desirable after triggering a reset.
   procedure Reset is null;

   --  Get raw 6-axis motion sensor readings (accel/gyro).
   --  Retrieves all currently available motion sensor values.
   procedure Get_Motion_6
   (Acc_X  : out Integer_16;
    Acc_Y  : out Integer_16;
    Acc_Z  : out Integer_16;
    Gyro_X : out Integer_16;
    Gyro_Y : out Integer_16;
    Gyro_Z : out Integer_16) is
      SCALE_ACC : constant := (2.0**15-1.0)/(8.0 * 9.819); --  Acc: map -8g...+8g => -2^15-1 .. 2^15
      SCALE_GYR : constant := (1.0/3.1416*180.0)/2000.0 * (2.0**15-1.0); --  Gyr: map +/- 35 rad/s => -2^15-1 .. 2^15
   begin


      Acc_X := Integer_16 (Simulation.CSV_here.Get_Column ("accY") * (-SCALE_ACC));
      Acc_Y := Integer_16 (Simulation.CSV_here.Get_Column ("accX") * SCALE_ACC);
      Acc_Z := Integer_16 (Simulation.CSV_here.Get_Column ("accZ") * SCALE_ACC);
      Gyro_X := Integer_16 (Simulation.CSV_here.Get_Column ("gyroY") * (SCALE_GYR));
      Gyro_Y := Integer_16 (Simulation.CSV_here.Get_Column ("gyroX") * SCALE_GYR);
      Gyro_Z := Integer_16 (Simulation.CSV_here.Get_Column ("gyroZ") * SCALE_GYR);




      -- Gyro_Y = 17.9
   end Get_Motion_6;

   --  Set clock source setting.
   --  3 bits allowed to choose the source. The different
   --  clock sources are enumerated in the MPU6000 register map.
   procedure Set_Clock_Source (Clock_Source : MPU6000_Clock_Source) is null;

   --  Set digital low-pass filter configuration.
   procedure Set_DLPF_Mode (DLPF_Mode : MPU6000_DLPF_Bandwidth_Mode) is null;

   --  Set full-scale gyroscope range.
   procedure Set_Full_Scale_Gyro_Range
   (FS_Range : MPU6000_FS_Gyro_Range) is null;

   --  Set full-scale acceler range.
   procedure Set_Full_Scale_Accel_Range
   (FS_Range : MPU6000_FS_Accel_Range) is null;

   --  Set I2C bypass enabled status.
   --  When this bit is equal to 1 and I2C_MST_EN (Register 106 bit[5]) is
   --  equal to 0, the host application processor
   --  will be able to directly access the
   --  auxiliary I2C bus of the MPU-60X0. When this bit is equal to 0,
   --  the host application processor will not be able to directly
   --  access the auxiliary I2C bus of the MPU-60X0 regardless of the state
   --  of I2C_MST_EN (Register 106 bit[5]).
   procedure Set_I2C_Bypass_Enabled (Value : Boolean) is null;

   --  Set interrupts enabled status.
   procedure Set_Int_Enabled (Value : Boolean) is null;

   --  Set gyroscope sample rate divider
   procedure Set_Rate (Rate_Div : HIL.Byte) is null;

   --  Set sleep mode status.
   procedure Set_Sleep_Enabled (Value : Boolean) is null;

   --  Set temperature sensor enabled status.
   procedure Set_Temp_Sensor_Enabled (Value : Boolean) is null;

   --  Get temperature sensor enabled status.
   function Get_Temp_Sensor_Enabled return Boolean is (True);

   function Evaluate_Self_Test
     (Low          : Float;
      High         : Float;
      Value        : Float;
      Debug_String : String) return Boolean is (True);

   --  Read data to the specified MPU6000 register
   procedure Read_Register
     (Reg_Addr    : Byte;
      Data        : in out Data_Type) is null;

   --  Read one byte at the specified MPU6000 register
   procedure Read_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : in out Byte) is null;

   --  Read one but at the specified MPU6000 register
   function Read_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : Unsigned_8_Bit_Index) return Boolean is (True);

   --  Write data to the specified MPU6000 register
   procedure Write_Register
     (Reg_Addr    : Byte;
      Data        : Data_Type) is null;

   --  Write one byte at the specified MPU6000 register
   procedure Write_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : Byte) is null;

   --  Write one bit at the specified MPU6000 register
   procedure Write_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : Unsigned_8_Bit_Index;
      Bit_Value : Boolean) is null;

   --  Write data in the specified register, starting from the
   --  bit specified in Start_Bit_Pos
   procedure Write_Bits_At_Register
     (Reg_Addr      : Byte;
      Start_Bit_Pos : Unsigned_8_Bit_Index;
      Data          : Byte;
      Length        : Unsigned_8_Bit_Index) is null;

   function Fuse_Low_And_High_Register_Parts
     (High : Byte;
      Low  : Byte) return Integer_16 is (0);
end MPU6000.Driver;
