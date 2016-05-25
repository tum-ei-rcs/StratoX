-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      MPU 6000 Driver
--
-- Authors:  Anthony Leonardo Gracio, Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Control a single LED


with Interfaces; use Interfaces;
with Ada.Real_Time;       use Ada.Real_Time;

-- with HIL; 
with HIL.SPI; use HIL;

use type HIL.SPI.Data_Type;

package MPU6000.Driver is

   --  Types and subtypes

   --  Type used to represent teh data we want to send via I2C
   subtype Data_Type is HIL.SPI.Data_Type; 

   --  Type reprensnting all the different clock sources of the MPU6000.
   --  See the MPU6000 register map section 4.4 for more details.
   type MPU6000_Clock_Source is
     (Internal_Clk,
      X_Gyro_Clk,
      Y_Gyro_Clk,
      Z_Gyro_Clk,
      External_32K_Clk,
      External_19M_Clk,
      Reserved_Clk,
      Stop_Clk);
   for MPU6000_Clock_Source use
     (Internal_Clk     => 16#00#,
      X_Gyro_Clk       => 16#01#,
      Y_Gyro_Clk       => 16#02#,
      Z_Gyro_Clk       => 16#03#,
      External_32K_Clk => 16#04#,
      External_19M_Clk => 16#05#,
      Reserved_Clk     => 16#06#,
      Stop_Clk         => 16#07#);
   for MPU6000_Clock_Source'Size use 3;

   --  Type representing the allowed full scale ranges
   --  for MPU6000 gyroscope.
   type MPU6000_FS_Gyro_Range is
     (MPU6000_Gyro_FS_250,
      MPU6000_Gyro_FS_500,
      MPU6000_Gyro_FS_1000,
      MPU6000_Gyro_FS_2000);
   for MPU6000_FS_Gyro_Range use
     (MPU6000_Gyro_FS_250  => 16#00#,
      MPU6000_Gyro_FS_500  => 16#01#,
      MPU6000_Gyro_FS_1000 => 16#02#,
      MPU6000_Gyro_FS_2000 => 16#03#);
   for MPU6000_FS_Gyro_Range'Size use 2;

   --  Type representing the allowed full scale ranges
   --  for MPU6000 accelerometer.
   type MPU6000_FS_Accel_Range is
     (MPU6000_Accel_FS_2,
      MPU6000_Accel_FS_4,
      MPU6000_Accel_FS_8,
      MPU6000_Accel_FS_16);
   for MPU6000_FS_Accel_Range use
     (MPU6000_Accel_FS_2  => 16#00#,
      MPU6000_Accel_FS_4  => 16#01#,
      MPU6000_Accel_FS_8  => 16#02#,
      MPU6000_Accel_FS_16 => 16#03#);
   for MPU6000_FS_Accel_Range'Size use 2;

   type MPU6000_DLPF_Bandwidth_Mode is
     (MPU6000_DLPF_BW_256,
      MPU6000_DLPF_BW_188,
      MPU6000_DLPF_BW_98,
      MPU6000_DLPF_BW_42,
      MPU6000_DLPF_BW_20,
      MPU6000_DLPF_BW_10,
      MPU6000_DLPF_BW_5);
   for MPU6000_DLPF_Bandwidth_Mode use
     (MPU6000_DLPF_BW_256 => 16#00#,
      MPU6000_DLPF_BW_188 => 16#01#,
      MPU6000_DLPF_BW_98  => 16#02#,
      MPU6000_DLPF_BW_42  => 16#03#,
      MPU6000_DLPF_BW_20  => 16#04#,
      MPU6000_DLPF_BW_10  => 16#05#,
      MPU6000_DLPF_BW_5   => 16#06#);
   for MPU6000_DLPF_Bandwidth_Mode'Size use 3;

   --  Use to convert MPU6000 registers in degrees (gyro) and G (acc).
   MPU6000_DEG_PER_LSB_250  : constant := (2.0 * 250.0) / 65536.0;
   MPU6000_DEG_PER_LSB_500  : constant := (2.0 * 500.0) / 65536.0;
   MPU6000_DEG_PER_LSB_1000 : constant := (2.0 * 1000.0) / 65536.0;
   MPU6000_DEG_PER_LSB_2000 : constant := (2.0 * 2000.0) / 65536.0;
   MPU6000_G_PER_LSB_2      : constant := (2.0 * 2.0) / 65536.0;
   MPU6000_G_PER_LSB_4      : constant := (2.0 * 4.0) / 65536.0;
   MPU6000_G_PER_LSB_8      : constant := (2.0 * 8.0) / 65536.0;
   MPU6000_G_PER_LSB_16     : constant := (2.0 * 16.0) / 65536.0;




   --  Procedures and functions

   --  Initialize the MPU6000 Device via I2C.
   procedure Init;

   --  Test if the MPU6000 is initialized and connected.
   function Test return Boolean;

   --  Test if we are connected to MPU6000 via I2C.
   function Test_Connection return Boolean;

   --  MPU6000 self test.
   function Self_Test return Boolean;

   --  Reset the MPU6000 device.
   --  A small delay of ~50ms may be desirable after triggering a reset.
   procedure Reset;

   --  Get raw 6-axis motion sensor readings (accel/gyro).
   --  Retrieves all currently available motion sensor values.
   procedure Get_Motion_6
   (Acc_X  : out Integer_16;
    Acc_Y  : out Integer_16;
    Acc_Z  : out Integer_16;
    Gyro_X : out Integer_16;
    Gyro_Y : out Integer_16;
    Gyro_Z : out Integer_16);

   --  Set clock source setting.
   --  3 bits allowed to choose the source. The different
   --  clock sources are enumerated in the MPU6000 register map.
   procedure Set_Clock_Source (Clock_Source : MPU6000_Clock_Source);

   --  Set digital low-pass filter configuration.
   procedure Set_DLPF_Mode (DLPF_Mode : MPU6000_DLPF_Bandwidth_Mode);

   --  Set full-scale gyroscope range.
   procedure Set_Full_Scale_Gyro_Range
   (FS_Range : MPU6000_FS_Gyro_Range);

   --  Set full-scale acceler range.
   procedure Set_Full_Scale_Accel_Range
   (FS_Range : MPU6000_FS_Accel_Range);

   --  Set I2C bypass enabled status.
   --  When this bit is equal to 1 and I2C_MST_EN (Register 106 bit[5]) is
   --  equal to 0, the host application processor
   --  will be able to directly access the
   --  auxiliary I2C bus of the MPU-60X0. When this bit is equal to 0,
   --  the host application processor will not be able to directly
   --  access the auxiliary I2C bus of the MPU-60X0 regardless of the state
   --  of I2C_MST_EN (Register 106 bit[5]).
   procedure Set_I2C_Bypass_Enabled (Value : Boolean);

   --  Set interrupts enabled status.
   procedure Set_Int_Enabled (Value : Boolean);

   --  Set gyroscope sample rate divider
   procedure Set_Rate (Rate_Div : HIL.Byte);

   --  Set sleep mode status.
   procedure Set_Sleep_Enabled (Value : Boolean);

   --  Set temperature sensor enabled status.
   procedure Set_Temp_Sensor_Enabled (Value : Boolean);

   --  Get temperature sensor enabled status.
   function Get_Temp_Sensor_Enabled return Boolean;


private

   --  Global variables and constants

   Is_Init : Boolean := False;
   Device_Address : HIL.Byte;

   --  MPU6000 Device ID. Use to test if we are connected via I2C
   MPU6000_DEVICE_ID        : constant := 16#71#;
   --  Address pin low (GND), default for InvenSense evaluation board
   MPU6000_ADDRESS_AD0_LOW  : constant := 16#68#;
   --  Address pin high (VCC)
   MPU6000_ADDRESS_AD0_HIGH : constant := 16#69#;

   MPU6000_STARTUP_TIME_MS : constant Time
     := Time_First + Milliseconds (1_000);

   --  Procedures and functions

   --  Evaluate the self test and print the result of this evluation
   --  with the given string prepended
   function Evaluate_Self_Test
     (Low          : Float;
      High         : Float;
      Value        : Float;
      Debug_String : String) return Boolean;

   --  Read data to the specified MPU6000 register
   procedure Read_Register
     (Reg_Addr    : Byte;
      Data        : in out Data_Type);

   --  Read one byte at the specified MPU6000 register
   procedure Read_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : in out Byte);

   --  Read one but at the specified MPU6000 register
   function Read_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : Byte_Bit_Position) return Boolean;

   --  Write data to the specified MPU6000 register
   procedure Write_Register
     (Reg_Addr    : Byte;
      Data        : Data_Type);

   --  Write one byte at the specified MPU6000 register
   procedure Write_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : Byte);

   --  Write one bit at the specified MPU6000 register
   procedure Write_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : Byte_Bit_Position;
      Bit_Value : Boolean);

   --  Write data in the specified register, starting from the
   --  bit specified in Start_Bit_Pos
   procedure Write_Bits_At_Register
     (Reg_Addr      : Byte;
      Start_Bit_Pos : Byte_Bit_Position;
      Data          : Byte;
      Length        : Byte_Bit_Position);

   function Fuse_Low_And_High_Register_Parts
     (High : Byte;
      Low  : Byte) return Integer_16;
   pragma Inline (Fuse_Low_And_High_Register_Parts);

end MPU6000.Driver;
