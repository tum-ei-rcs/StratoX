
with MPU6000.Register; use MPU6000.Register;

with Ada.Unchecked_Conversion;
--with Config.Software;


package body MPU6000.Driver with SPARK_Mode,
  Refined_State => (State => Is_Init)
is

   READ_FLAG : constant Byte := Byte( 2#1000_0000# );

   --  Public procedures and functions
      

   ------------------
   -- MPU6000_Test --
   ------------------

   function Test return Boolean is
   begin
      return Is_Init;
   end Test;
   
  
   --  Private procedures and functions

   --------------------------------
   -- Evaluate_Self_Test --
   --------------------------------

   function Evaluate_Self_Test
     (Low          : Float;
      High         : Float;
      Value        : Float;
      Debug_String : String) return Boolean
   is
      pragma Unreferenced (Debug_String);
      ret : Boolean;
   begin
      if Value not in Low .. High then
         ret := False;
      else
         ret := True;
      end if;
      return ret;
   end Evaluate_Self_Test;

   ---------------------------
   -- Read_Register --
   ---------------------------

   procedure Read_Register
     (Reg_Addr    : Byte;
      Data        : in out Data_Type) 
     with SPARK_Mode => Off -- SPARK: subtype constraint for Data_RX cannot depend on Data'Length
   is
      Data_TX : constant Data_Type := (Reg_Addr + READ_FLAG) & Data;      
      Data_RX : Data_Type (1 .. Data'Length + 1) := (others => Byte(0)); 
   begin
      HIL.SPI.transceive(HIL.SPI.MPU6000, Data_TX, Data_RX );  -- send the amount of bytes that should be read
      Data := Data_RX(2 .. Data_RX'Length);
   end Read_Register;

   -----------------------------------
   -- Read_Byte_At_Register --
   -----------------------------------

   procedure Read_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : in out Byte) 
   is
      Data_RX : Data_Type := (1 .. 2 => Byte( 0 ) );
   begin
      --HIL.SPI.write(HIL.SPI.MPU6000, (1 => Reg_Addr) );
      HIL.SPI.transceive(HIL.SPI.MPU6000, (1 => (Reg_Addr + READ_FLAG), 2 => Data), Data_RX );
      Data := Data_RX(2);
   end Read_Byte_At_Register;

   ----------------------------------
   -- Read_Bit_At_Register --
   ----------------------------------

   procedure Read_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : Unsigned_8_Bit_Index;
      Bit_Value : out Boolean)
   is
      Register_Value : Byte := Byte (0);
      
   begin
      Read_Byte_At_Register (Reg_Addr, Register_Value);
      Bit_Value := (if (Register_Value and Shift_Left (1, Bit_Pos)) /= 0 then
                       True
                    else
                       False);
   end Read_Bit_At_Register;

   ----------------------------
   -- Write_Register --
   ----------------------------

   procedure Write_Register
     (Reg_Addr    : Byte;
      Data        : Data_Type) 
   is
      Data_TX : constant Data_Type := Reg_Addr & Data;
   begin
      HIL.SPI.write(HIL.SPI.MPU6000, Data_TX);
   end Write_Register;

   ------------------------------------
   -- Write_Byte_At_Register --
   ------------------------------------

   procedure Write_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : Byte) 
   is
      Data_TX : constant Data_Type := (1 => Reg_Addr) & Data;
   begin
      HIL.SPI.write(HIL.SPI.MPU6000, Data_TX);
   end Write_Byte_At_Register;

   -----------------------------------
   -- Write_Bit_At_Register --
   -----------------------------------

   procedure Write_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : Unsigned_8_Bit_Index;
      Bit_Value : Boolean)
   is
      Register_Value : Byte := Byte( 0 );
   begin
      Read_Byte_At_Register (Reg_Addr, Register_Value);

      Register_Value := (if Bit_Value then
                            Register_Value or (Shift_Left (1, Bit_Pos))
                         else
                            Register_Value and not (Shift_Left (1, Bit_Pos)));

      Write_Byte_At_Register (Reg_Addr, Register_Value);
   end Write_Bit_At_Register;

   ------------------------------------
   -- Write_Bits_At_Register --
   ------------------------------------

   procedure Write_Bits_At_Register
     (Reg_Addr      : Byte;
      Start_Bit_Pos : Unsigned_8_Bit_Index;
      Data          : Byte;
      Length        : Unsigned_8_Bit_Index)
   is
      Register_Value : Byte := Byte (0);
      Mask           : Byte;
      Data_Aux       : Byte := Data;
   begin
      Read_Byte_At_Register (Reg_Addr, Register_Value);

      Mask := Shift_Left
        ((Shift_Left (1, Length) - 1), Start_Bit_Pos - Length + 1);
      Data_Aux := Shift_Left
        (Data_Aux, Start_Bit_Pos - Length + 1);
      Data_Aux := Data_Aux and Mask;
      Register_Value := Register_Value and not Mask;
      Register_Value := Register_Value or Data_Aux;

      Write_Byte_At_Register (Reg_Addr, Register_Value);
   end Write_Bits_At_Register;

   --------------------------------------
   -- Fuse_Low_And_High_Register_Parts --
   --------------------------------------

   function Fuse_Low_And_High_Register_Parts
     (High : Byte;
      Low  : Byte) return Integer_16
   is
      -------------------------
      -- Unsigned_16_To_Integer_16 --
      -------------------------

      function Unsigned_16_To_Integer_16 is new Ada.Unchecked_Conversion
        (Unsigned_16, Integer_16);

      Register : Unsigned_16;
   begin
      Register := Shift_Left (Unsigned_16 (High), 8);
      Register := Register or Unsigned_16 (Low);

      return Unsigned_16_To_Integer_16 (Register);
   end Fuse_Low_And_High_Register_Parts;  
   
   ------------------------------
   -- MPU6000_Set_Clock_Source --
   ------------------------------

   procedure Set_Clock_Source (Clock_Source : MPU6000_Clock_Source) with SPARK_Mode => Off  -- not allowed: Enum'Rep
   is
   begin
      Write_Bits_At_Register
        (Reg_Addr      => MPU6000_RA_PWR_MGMT_1,
         Start_Bit_Pos => MPU6000_PWR1_CLKSEL_BIT,
         Data          => MPU6000_Clock_Source'Enum_Rep (Clock_Source),
         Length        => MPU6000_PWR1_CLKSEL_LENGTH);
   end Set_Clock_Source;

   ---------------------------
   -- MPU6000_Set_DLPF_Mode --
   ---------------------------

   procedure Set_DLPF_Mode (DLPF_Mode : MPU6000_DLPF_Bandwidth_Mode) with SPARK_Mode => Off  -- not allowed: Enum'Rep
   is
   begin
      Write_Bits_At_Register
        (Reg_Addr      => MPU6000_RA_CONFIG,
         Start_Bit_Pos => MPU6000_CFG_DLPF_CFG_BIT,
         Data          => MPU6000_DLPF_Bandwidth_Mode'Enum_Rep (DLPF_Mode),
         Length        => MPU6000_CFG_DLPF_CFG_LENGTH);
   end Set_DLPF_Mode;

   ---------------------------------------
   -- MPU6000_Set_Full_Scale_Gyro_Range --
   ---------------------------------------

   procedure Set_Full_Scale_Gyro_Range
     (FS_Range : MPU6000_FS_Gyro_Range) with SPARK_Mode => Off  -- not allowed: Enum'Rep
   is
   begin
      Write_Bits_At_Register
        (Reg_Addr      => MPU6000_RA_GYRO_CONFIG,
         Start_Bit_Pos => MPU6000_GCONFIG_FS_SEL_BIT,
         Data          => MPU6000_FS_Gyro_Range'Enum_Rep (FS_Range),
         Length        => MPU6000_GCONFIG_FS_SEL_LENGTH);
   end Set_Full_Scale_Gyro_Range;

   ----------------------------------------
   -- MPU6000_Set_Full_Scale_Accel_Range --
   ----------------------------------------

   procedure Set_Full_Scale_Accel_Range
     (FS_Range : MPU6000_FS_Accel_Range) with SPARK_Mode => Off  -- not allowed: Enum'Rep 
   is
   begin
      Write_Bits_At_Register
        (Reg_Addr      => MPU6000_RA_ACCEL_CONFIG,
         Start_Bit_Pos => MPU6000_ACONFIG_AFS_SEL_BIT,
         Data          => MPU6000_FS_Accel_Range'Enum_Rep (FS_Range),
         Length        => MPU6000_ACONFIG_AFS_SEL_LENGTH);
   end Set_Full_Scale_Accel_Range;

   ------------------------------------
   -- MPU6000_Set_I2C_Bypass_Enabled --
   ------------------------------------

   procedure Set_I2C_Bypass_Enabled (Value : Boolean) is
   begin
      Write_Bit_At_Register
        (Reg_Addr  => MPU6000_RA_INT_PIN_CFG,
         Bit_Pos   => MPU6000_INTCFG_I2C_BYPASS_EN_BIT,
         Bit_Value => Value);
   end Set_I2C_Bypass_Enabled;

   -----------------------------
   -- MPU6000_Set_Int_Enabled --
   -----------------------------

   procedure Set_Int_Enabled (Value : Boolean) is
   begin
      --  Full register byte for all interrupts, for quick reading.
      --  Each bit should be set 0 for disabled, 1 for enabled.
      if Value then
         Write_Byte_At_Register
           (Reg_Addr => MPU6000_RA_INT_ENABLE,
            Data     => 16#FF#);
      else
         Write_Byte_At_Register
           (Reg_Addr => MPU6000_RA_INT_ENABLE,
            Data     => 16#00#);
      end if;
   end Set_Int_Enabled;

   ----------------------
   -- MPU6000_Set_Rate --
   ----------------------

   procedure Set_Rate (Rate_Div : Byte) is
   begin
      Write_Byte_At_Register
        (Reg_Addr => MPU6000_RA_SMPLRT_DIV,
         Data     => Rate_Div);
   end Set_Rate;

   -------------------------------
   -- MPU6000_Set_Sleep_Enabled --
   -------------------------------

   procedure Set_Sleep_Enabled (Value : Boolean) is
   begin
      Write_Bit_At_Register
        (Reg_Addr  => MPU6000_RA_PWR_MGMT_1,
         Bit_Pos   => MPU6000_PWR1_SLEEP_BIT,
         Bit_Value => Value);
   end Set_Sleep_Enabled;

   -------------------------------------
   -- MPU6000_Set_Temp_Sensor_Enabled --
   -------------------------------------

   procedure Set_Temp_Sensor_Enabled (Value : Boolean) is
   begin
      --  True value for this bit actually disables it.
      Write_Bit_At_Register
        (Reg_Addr  => MPU6000_RA_PWR_MGMT_1,
         Bit_Pos   => MPU6000_PWR1_TEMP_DIS_BIT,
         Bit_Value => not Value);
   end Set_Temp_Sensor_Enabled;

   -------------------------------------
   -- MPU6000_Get_Temp_Sensor_Enabled --
   -------------------------------------

   procedure Get_Temp_Sensor_Enabled (ret : out Boolean) is
      bit : Boolean;
   begin    
      Read_Bit_At_Register
        (Reg_Addr  => MPU6000_RA_PWR_MGMT_1,
         Bit_Pos   => MPU6000_PWR1_TEMP_DIS_BIT,
         Bit_Value => bit);

      --  False value for this bit means that it is enabled
      ret := not bit;
   end Get_Temp_Sensor_Enabled;
   
   --------------------------
   -- MPU6000_Get_Motion_6 --
   --------------------------

   procedure Get_Motion_6
     (Acc_X  : out Integer_16;
      Acc_Y  : out Integer_16;
      Acc_Z  : out Integer_16;
      Gyro_X : out Integer_16;
      Gyro_Y : out Integer_16;
      Gyro_Z : out Integer_16)
   is
      Raw_Data : Data_Type (1 .. 14);
   begin
      Read_Register
        (Reg_Addr => MPU6000_RA_ACCEL_XOUT_H,
         Data     => Raw_Data);

      Acc_X :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (1), Raw_Data (2));
      Acc_Y :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (3), Raw_Data (4));
      Acc_Z :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (5), Raw_Data (6));

      Gyro_X :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (9), Raw_Data (10));
      Gyro_Y :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (11), Raw_Data (12));
      Gyro_Z :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (13), Raw_Data (14));
   end Get_Motion_6;
   
   -----------------------------
   -- MPU6000_Test_Connection --
   -----------------------------

   procedure Test_Connection  (success : out Boolean)
   is
      Who_Am_I : Byte := Byte( 0 );
   begin
      Read_Byte_At_Register
        (Reg_Addr => MPU6000_RA_WHO_AM_I,
         Data     => Who_Am_I);

      success := Who_Am_I = MPU6000_DEVICE_ID;
   end Test_Connection;

   -----------------------
   -- MPU6000_Self_Test --
   -----------------------

   procedure Self_Test (Test_Status : out Boolean) 
   is
      subtype Integer_32_Array_3 is Integer_32_Array (1 .. 3);
      subtype Integer_32_Array_6 is Integer_32_Array (1 .. 6);
      subtype Float_Array_3 is Float_Array (1 .. 3);

      Raw_Data    : Data_Type (1 .. 6) := (others => 0);
      Saved_Reg   : Data_Type (1 .. 4) := (others => 0);
      Self_Test   : Data_Type (1 .. 6) := (others => 0);
      Acc_Avg     : Integer_32_Array_3 := (others => 0);
      Gyro_Avg    : Integer_32_Array_3 := (others => 0);
      Acc_ST_Avg  : Integer_32_Array_3 := (others => 0);
      Gyro_ST_Avg : Integer_32_Array_3 := (others => 0);

      Factory_Trim : Integer_32_Array_6 := (others => 0);
      Acc_Diff     : Float_Array_3;
      Gyro_Diff    : Float_Array_3;
      FS           : constant Natural := 0;

   begin
      --  Save old configuration
      Read_Byte_At_Register (MPU6000_RA_SMPLRT_DIV, Saved_Reg (1));
      Read_Byte_At_Register (MPU6000_RA_CONFIG, Saved_Reg (2));
      Read_Byte_At_Register (MPU6000_RA_GYRO_CONFIG, Saved_Reg (3));
      Read_Byte_At_Register (MPU6000_RA_ACCEL_CONFIG, Saved_Reg (4));

      --  Write test configuration
      Write_Byte_At_Register (MPU6000_RA_SMPLRT_DIV, 16#00#);
      Write_Byte_At_Register (MPU6000_RA_CONFIG, 16#02#);
      Write_Byte_At_Register (MPU6000_RA_GYRO_CONFIG,
                                      Shift_Left (1, FS));
      Write_Byte_At_Register (MPU6000_RA_ACCEL_CONFIG,
                                      Shift_Left (1, FS));

      --  Get average current values of gyro and accelerometer
      for I in 1 .. 200 loop
         Read_Register (MPU6000_RA_ACCEL_XOUT_H, Raw_Data);
         Acc_Avg (1) :=
           Acc_Avg (1) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (1), Raw_Data (2)));
         Acc_Avg (2) :=
           Acc_Avg (2) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (3), Raw_Data (4)));
         Acc_Avg (3) :=
           Acc_Avg (3) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (5), Raw_Data (6)));

         Read_Register (MPU6000_RA_GYRO_XOUT_H, Raw_Data);
         Gyro_Avg (1) :=
           Gyro_Avg (1) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (1), Raw_Data (2)));
         Gyro_Avg (2) :=
           Gyro_Avg (2) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (3), Raw_Data (4)));
         Gyro_Avg (3) :=
           Gyro_Avg (3) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (5), Raw_Data (6)));
      end loop;

      --  Get average of 200 values and store as average current readings
      for I in Integer_32_Array_3'Range loop
         Acc_Avg (I) := Acc_Avg (I) / 200;
         Gyro_Avg (I) := Gyro_Avg (I) / 200;
      end loop;

      --  Configure the acceleromter for self test
      Write_Byte_At_Register (MPU6000_RA_ACCEL_CONFIG, 16#E0#);
      Write_Byte_At_Register (MPU6000_RA_GYRO_CONFIG, 16#E0#);

      --  Delay a while to let the device stabilize
      declare
         now : Ada.Real_Time.Time := Clock;
      begin
         delay until now + Milliseconds (25);  
      end;

      --  Get average self-test values of gyro and accelerometer
      for I in 1 .. 200 loop
         Read_Register (MPU6000_RA_ACCEL_XOUT_H, Raw_Data);
         Acc_ST_Avg (1) :=
           Acc_ST_Avg (1) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (1), Raw_Data (2)));
         Acc_ST_Avg (2) :=
           Acc_ST_Avg (2) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (3), Raw_Data (4)));
         Acc_ST_Avg (3) :=
           Acc_ST_Avg (3) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (5), Raw_Data (6)));

         Read_Register (MPU6000_RA_GYRO_XOUT_H, Raw_Data);
         Gyro_ST_Avg (1) :=
           Gyro_ST_Avg (1) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (1), Raw_Data (2)));
         Gyro_ST_Avg (2) :=
           Gyro_ST_Avg (2) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (3), Raw_Data (4)));
         Gyro_ST_Avg (3) :=
           Gyro_ST_Avg (3) +
           Integer_32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (5), Raw_Data (6)));
      end loop;

      --  Get average of 200 values and store as average self-test readings
      for I in Integer_32_Array_3'Range loop
         Acc_ST_Avg (I) := Acc_ST_Avg (I) / 200;
         Gyro_ST_Avg (I) := Gyro_ST_Avg (I) / 200;
      end loop;

      --  Configure the gyro and accelerometer for normal operation
      Write_Byte_At_Register (MPU6000_RA_ACCEL_CONFIG, 16#00#);
      Write_Byte_At_Register (MPU6000_RA_GYRO_CONFIG, 16#00#);

      --  Delay a while to let the device stabilize
      declare
         now : Ada.Real_Time.Time := Clock;
      begin
         delay until now + Milliseconds (25);  
      end;

      --  Retrieve Accelerometer and Gyro Factory Self - Test Code From USR_Reg
      Read_Byte_At_Register (MPU6000_RA_SELF_TEST_X, Self_Test (1));
      Read_Byte_At_Register (MPU6000_RA_SELF_TEST_Y, Self_Test (2));
      Read_Byte_At_Register (MPU6000_RA_SELF_TEST_Z, Self_Test (3));
      Read_Byte_At_Register (MPU6000_RA_SELF_TEST_X, Self_Test (4));
      Read_Byte_At_Register (MPU6000_RA_SELF_TEST_Y, Self_Test (5));
      Read_Byte_At_Register (MPU6000_RA_SELF_TEST_Z, Self_Test (6));

      for I in 1 .. 6 loop
         if Self_Test (I) /= 0 then
            Factory_Trim (I) := Integer_32
              (MPU6000_ST_TB (Integer (Self_Test (I))));
         else
            Factory_Trim (I) := 0;
         end if;
      end loop;

      --  Report results as a ratio of (STR - FT)/FT; the change from
      --  Factory Trim of the Self - Test Response
      --  To get percent, must multiply by 100

      for I in 1 .. 3 loop
         Acc_Diff (I) :=
           100.0 * (Float (Acc_ST_Avg (I) - Acc_Avg (I) - Factory_Trim (I)) /
                      Float (Factory_Trim (I)));
         Gyro_Diff (I) :=
           100.0 * (Float (Gyro_ST_Avg (I) - Gyro_Avg (I) -
                      Factory_Trim (I + 3)) /
                      Float (Factory_Trim (I + 3)));
      end loop;

      --  Restore old configuration
      Write_Byte_At_Register
        (MPU6000_RA_SMPLRT_DIV, Saved_Reg (1));
      Write_Byte_At_Register
        (MPU6000_RA_CONFIG, Saved_Reg (2));
      Write_Byte_At_Register
        (MPU6000_RA_GYRO_CONFIG, Saved_Reg (3));
      Write_Byte_At_Register
        (MPU6000_RA_ACCEL_CONFIG, Saved_Reg (4));

      --  Check result
      Test_Status := Evaluate_Self_Test
        (MPU6000_ST_GYRO_LOW, MPU6000_ST_GYRO_HIGH, Gyro_Diff (1), "gyro X");
      Test_Status := Test_Status and
        Evaluate_Self_Test
          (MPU6000_ST_GYRO_LOW, MPU6000_ST_GYRO_HIGH, Gyro_Diff (2), "gyro Y");
      Test_Status := Test_Status and
        Evaluate_Self_Test
          (MPU6000_ST_GYRO_LOW, MPU6000_ST_GYRO_HIGH, Gyro_Diff (3), "gyro Z");
      Test_Status := Test_Status and
        Evaluate_Self_Test
          (MPU6000_ST_ACCEL_LOW, MPU6000_ST_ACCEL_HIGH, Acc_Diff (1), "acc X");
      Test_Status := Test_Status and
        Evaluate_Self_Test
          (MPU6000_ST_ACCEL_LOW, MPU6000_ST_ACCEL_HIGH, Acc_Diff (2), "acc Y");
      Test_Status := Test_Status and
        Evaluate_Self_Test
          (MPU6000_ST_ACCEL_LOW, MPU6000_ST_ACCEL_HIGH, Acc_Diff (3), "acc Z");

   end Self_Test;

   -------------------
   -- MPU6000_Reset --
   -------------------

   procedure Reset is
   begin
      Write_Bit_At_Register
        (Reg_Addr  => MPU6000_RA_PWR_MGMT_1,
         Bit_Pos   => MPU6000_PWR1_DEVICE_RESET_BIT,
         Bit_Value => True);
   end Reset;
   
   ------------------
   -- MPU6000_Init --
   ------------------

   procedure Init is
   begin
      if Is_Init then
         return;
      end if;
       
      --  Wait for MPU6000 startup
      delay until MPU6000_STARTUP_TIME_MS;
      
      -- Wake-Up 
      Write_Bit_At_Register(MPU6000_RA_PWR_MGMT_1, MPU6000_PWR1_SLEEP_BIT, False);
      declare
         now : constant Ada.Real_Time.Time := Clock;
      begin
         delay until now + Milliseconds (10);  
      end;

      -- Disable I2C
      Write_Bit_At_Register(MPU6000_RA_USER_CTRL, MPU6000_USERCTRL_I2C_IF_DIS_BIT, True); 
      
      -- set Clock
      Set_Clock_Source(Z_Gyro_Clk);
      
      -- set sample rate
      -- Sample Rate = Gyroscope Output Rate / (1 + SMPLRT_DIV)
      -- Gyroscope Output Rate = (if DLPF = enabled then 1kHz else 8kHz)
      Set_Rate( Byte( 19 ) );   -- 50Hz
      
      
      -- set digital low pass filter (DLPF)
      Set_DLPF_Mode(MPU6000_DLPF_BW_20);

      --  Determine the device's I2C address (FIXME: why? this is SPI)
      declare
         hypothetical_i2c_address : constant HIL.Byte := Shift_Left (MPU6000_ADDRESS_AD0_HIGH, 1);
      begin
         null;
      end;

      --  Delay to wait for the state initialization of SCL and SDA
      declare
         now : constant Ada.Real_Time.Time := Clock;
      begin
         delay until now + Milliseconds (5);  
      end;

   end Init;
      
end MPU6000.Driver;
