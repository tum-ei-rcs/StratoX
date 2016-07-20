with CSV;
with Simulation;
with Ada.Text_IO; use Ada.Text_IO;

package body MPU6000.Driver  with
Refined_State => (State => (Is_Init, have_data, csv_file, Device_Address))
is

   package CSV_here is new CSV (filename => "mpu6000.csv");
   have_data : Boolean := False;
   csv_file : File_Type;

   procedure Init is
   begin
      if not CSV_here.Open then
         Put_Line ("MPU6000: Error opening file");
         Simulation.Finished := True;
         return;
      else
         Put_Line ("MPU6000: Replay from file");
         have_data := True;
         CSV_here.Parse_Header;
      end if;
   end Init;

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
   begin
      if not have_data and then CSV_here.End_Of_File then
         Simulation.Finished := True;
         Put_Line ("MPU6000: EOF");
         return;
      end if;

      if not csv_here.Parse_Row then
         Simulation.Finished := True;
         Put_Line ("MPU6000: Row error");
      end if;

      Acc_X := Integer_16 (CSV_here.Get_Column ("accx"));
      Acc_Y := Integer_16 (CSV_here.Get_Column ("accy"));
      Acc_Z := Integer_16 (CSV_here.Get_Column ("accz"));
      Gyro_X := Integer_16 (CSV_here.Get_Column ("gyrx"));
      Gyro_Y := Integer_16 (CSV_here.Get_Column ("gyry"));
      Gyro_Z := Integer_16 (CSV_here.Get_Column ("gyrz"));
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
