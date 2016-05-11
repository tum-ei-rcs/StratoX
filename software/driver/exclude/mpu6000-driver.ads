-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      MPU 6000 Driver
--
-- Authors:  Anthony Leonardo Gracio, Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Control a single LED


with MPU6000.Register;
with Ada.Real_Time;       use Ada.Real_Time;

with HIL.SPI;


package MPU6000.Driver is

   --  Types and subtypes

   --  Type used to represent teh data we want to send via I2C
   type I2C_Data is array (Positive range <>) of Byte;

   --  Type reprensnting all the different clock sources of the MPU9250.
   --  See the MPU9250 register map section 4.4 for more details.
   type MPU9250_Clock_Source is
     (Internal_Clk,
      X_Gyro_Clk,
      Y_Gyro_Clk,
      Z_Gyro_Clk,
      External_32K_Clk,
      External_19M_Clk,
      Reserved_Clk,
      Stop_Clk);
   for MPU9250_Clock_Source use
     (Internal_Clk     => 16#00#,
      X_Gyro_Clk       => 16#01#,
      Y_Gyro_Clk       => 16#02#,
      Z_Gyro_Clk       => 16#03#,
      External_32K_Clk => 16#04#,
      External_19M_Clk => 16#05#,
      Reserved_Clk     => 16#06#,
      Stop_Clk         => 16#07#);
   for MPU9250_Clock_Source'Size use 3;

   --  Type representing the allowed full scale ranges
   --  for MPU9250 gyroscope.
   type MPU9250_FS_Gyro_Range is
     (MPU9250_Gyro_FS_250,
      MPU9250_Gyro_FS_500,
      MPU9250_Gyro_FS_1000,
      MPU9250_Gyro_FS_2000);
   for MPU9250_FS_Gyro_Range use
     (MPU9250_Gyro_FS_250  => 16#00#,
      MPU9250_Gyro_FS_500  => 16#01#,
      MPU9250_Gyro_FS_1000 => 16#02#,
      MPU9250_Gyro_FS_2000 => 16#03#);
   for MPU9250_FS_Gyro_Range'Size use 2;

   --  Type representing the allowed full scale ranges
   --  for MPU9250 accelerometer.
   type MPU9250_FS_Accel_Range is
     (MPU9250_Accel_FS_2,
      MPU9250_Accel_FS_4,
      MPU9250_Accel_FS_8,
      MPU9250_Accel_FS_16);
   for MPU9250_FS_Accel_Range use
     (MPU9250_Accel_FS_2  => 16#00#,
      MPU9250_Accel_FS_4  => 16#01#,
      MPU9250_Accel_FS_8  => 16#02#,
      MPU9250_Accel_FS_16 => 16#03#);
   for MPU9250_FS_Accel_Range'Size use 2;

   type MPU9250_DLPF_Bandwidth_Mode is
     (MPU9250_DLPF_BW_256,
      MPU9250_DLPF_BW_188,
      MPU9250_DLPF_BW_98,
      MPU9250_DLPF_BW_42,
      MPU9250_DLPF_BW_20,
      MPU9250_DLPF_BW_10,
      MPU9250_DLPF_BW_5);
   for MPU9250_DLPF_Bandwidth_Mode use
     (MPU9250_DLPF_BW_256 => 16#00#,
      MPU9250_DLPF_BW_188 => 16#01#,
      MPU9250_DLPF_BW_98  => 16#02#,
      MPU9250_DLPF_BW_42  => 16#03#,
      MPU9250_DLPF_BW_20  => 16#04#,
      MPU9250_DLPF_BW_10  => 16#05#,
      MPU9250_DLPF_BW_5   => 16#06#);
   for MPU9250_DLPF_Bandwidth_Mode'Size use 3;

   --  Use to convert MPU9250 registers in degrees (gyro) and G (acc).
   MPU9250_DEG_PER_LSB_250  : constant := (2.0 * 250.0) / 65536.0;
   MPU9250_DEG_PER_LSB_500  : constant := (2.0 * 500.0) / 65536.0;
   MPU9250_DEG_PER_LSB_1000 : constant := (2.0 * 1000.0) / 65536.0;
   MPU9250_DEG_PER_LSB_2000 : constant := (2.0 * 2000.0) / 65536.0;
   MPU9250_G_PER_LSB_2      : constant := (2.0 * 2.0) / 65536.0;
   MPU9250_G_PER_LSB_4      : constant := (2.0 * 4.0) / 65536.0;
   MPU9250_G_PER_LSB_8      : constant := (2.0 * 8.0) / 65536.0;
   MPU9250_G_PER_LSB_16     : constant := (2.0 * 16.0) / 65536.0;




   --  Procedures and functions

   --  Initialize the MPU9250 Device via I2C.
   procedure MPU9250_Init;

   --  Test if the MPU9250 is initialized and connected.
   function MPU9250_Test return Boolean;

   --  Test if we are connected to MPU9250 via I2C.
   function MPU9250_Test_Connection return Boolean;

   --  MPU9250 self test.
   function MPU9250_Self_Test return Boolean;

   --  Reset the MPU9250 device.
   --  A small delay of ~50ms may be desirable after triggering a reset.
   procedure MPU9250_Reset;

   --  Get raw 6-axis motion sensor readings (accel/gyro).
   --  Retrieves all currently available motion sensor values.
   procedure MPU9250_Get_Motion_6
   (Acc_X  : out T_Int16;
    Acc_Y  : out T_Int16;
    Acc_Z  : out T_Int16;
    Gyro_X : out T_Int16;
    Gyro_Y : out T_Int16;
    Gyro_Z : out T_Int16);

   --  Set clock source setting.
   --  3 bits allowed to choose the source. The different
   --  clock sources are enumerated in the MPU9250 register map.
   procedure MPU9250_Set_Clock_Source (Clock_Source : MPU9250_Clock_Source);

   --  Set digital low-pass filter configuration.
   procedure MPU9250_Set_DLPF_Mode (DLPF_Mode : MPU9250_DLPF_Bandwidth_Mode);

   --  Set full-scale gyroscope range.
   procedure MPU9250_Set_Full_Scale_Gyro_Range
   (FS_Range : MPU9250_FS_Gyro_Range);

   --  Set full-scale acceler range.
   procedure MPU9250_Set_Full_Scale_Accel_Range
   (FS_Range : MPU9250_FS_Accel_Range);

   --  Set I2C bypass enabled status.
   --  When this bit is equal to 1 and I2C_MST_EN (Register 106 bit[5]) is
   --  equal to 0, the host application processor
   --  will be able to directly access the
   --  auxiliary I2C bus of the MPU-60X0. When this bit is equal to 0,
   --  the host application processor will not be able to directly
   --  access the auxiliary I2C bus of the MPU-60X0 regardless of the state
   --  of I2C_MST_EN (Register 106 bit[5]).
   procedure MPU9250_Set_I2C_Bypass_Enabled (Value : Boolean);

   --  Set interrupts enabled status.
   procedure MPU9250_Set_Int_Enabled (Value : Boolean);

   --  Set gyroscope sample rate divider
   procedure MPU9250_Set_Rate (Rate_Div : Byte);

   --  Set sleep mode status.
   procedure MPU9250_Set_Sleep_Enabled (Value : Boolean);

   --  Set temperature sensor enabled status.
   procedure MPU9250_Set_Temp_Sensor_Enabled (Value : Boolean);

   --  Get temperature sensor enabled status.
   function MPU9250_Get_Temp_Sensor_Enabled return Boolean;


private

   --  Global variables and constants

   Is_Init : Boolean := False;
   Device_Address : Byte;

   MPU9250_I2C_PORT     : I2C_Port renames I2C_3;
   MPU9250_I2C_OWN_ADDR : constant := 16#0074#;

   MPU9250_SCL_GPIO : GPIO_Port renames GPIO_A;
   MPU9250_SCL_Pin  : constant GPIO_Pin := Pin_8;
   MPU9250_SCL_AF   : GPIO_Alternate_Function := GPIO_AF_I2C3;

   MPU9250_SDA_GPIO : GPIO_Port renames GPIO_C;
   MPU9250_SDA_Pin  : constant GPIO_Pin := Pin_9;
   MPU9250_SDA_AF   : constant GPIO_Alternate_Function := GPIO_AF_I2C3;

   --  MPU9250 Device ID. Use to test if we are connected via I2C
   MPU9250_DEVICE_ID        : constant := 16#71#;
   --  Address pin low (GND), default for InvenSense evaluation board
   MPU9250_ADDRESS_AD0_LOW  : constant := 16#68#;
   --  Address pin high (VCC)
   MPU9250_ADDRESS_AD0_HIGH : constant := 16#69#;

   MPU9250_STARTUP_TIME_MS : constant Time
     := Time_First + Milliseconds (1_000);

   --  Procedures and functions

   --  Evaluate the self test and print the result of this evluation
   --  with the given string prepended
   function MPU9250_Evaluate_Self_Test
     (Low          : Float;
      High         : Float;
      Value        : Float;
      Debug_String : String) return Boolean;

   --  Initialize the GPIO pins of the I2C control lines
   procedure MPU9250_Init_Control_Lines;

   --  Configure I2C for MPU9250
   procedure MPU9250_Configure_I2C;

   --  Read data to the specified MPU9250 register
   procedure MPU9250_Read_Register
     (Reg_Addr    : Byte;
      Data        : in out I2C_Data);

   --  Read one byte at the specified MPU9250 register
   procedure MPU9250_Read_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : out Byte);

   --  Read one but at the specified MPU9250 register
   function MPU9250_Read_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : T_Bit_Pos_8) return Boolean;

   --  Write data to the specified MPU9250 register
   procedure MPU9250_Write_Register
     (Reg_Addr    : Byte;
      Data        : I2C_Data);

   --  Write one byte at the specified MPU9250 register
   procedure MPU9250_Write_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : Byte);

   --  Write one bit at the specified MPU9250 register
   procedure MPU9250_Write_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : T_Bit_Pos_8;
      Bit_Value : Boolean);

   --  Write data in the specified register, starting from the
   --  bit specified in Start_Bit_Pos
   procedure MPU9250_Write_Bits_At_Register
     (Reg_Addr      : Byte;
      Start_Bit_Pos : T_Bit_Pos_8;
      Data          : Byte;
      Length        : T_Bit_Pos_8);

   function Fuse_Low_And_High_Register_Parts
     (High : Byte;
      Low  : Byte) return T_Int16;
   pragma Inline (Fuse_Low_And_High_Register_Parts);

end MPU6000.Driver;
