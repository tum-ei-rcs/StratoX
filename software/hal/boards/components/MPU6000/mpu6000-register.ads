-- Project: MART - Modular Airborne Real-Time Testbed
-- System:  Emergency Recovery System
-- Authors: Markus Neumair (Original C-Code)
--          Emanuel Regnath (emanuel.regnath@tum.de) (Ada Port)
-- 
-- Module Description:
-- Driver for the IMU MPU6000

-- 
with HIL; use HIL;

private package MPU6000.Register with SPARK_Mode is

   type Address_Type is new HIL.Byte;

   --  MPU6000 register adresses and other defines

   MPU6000_REV_C4_ES : constant := 16#14#;
   MPU6000_REV_C5_ES : constant := 16#15#;
   MPU6000_REV_D6_ES : constant := 16#16#;
   MPU6000_REV_D7_ES : constant := 16#17#;
   MPU6000_REV_D8_ES : constant := 16#18#;
   MPU6000_REV_C4 : constant := 16#54#;
   MPU6000_REV_C5 : constant := 16#55#;
   MPU6000_REV_D6 : constant := 16#56#;
   MPU6000_REV_D7 : constant := 16#57#;
   MPU6000_REV_D8 : constant := 16#58#;
   MPU6000_REV_D9 : constant := 16#59#;

   -- MPU6000_RA_ST_X_GYRO      : constant := 16#00#;
   -- MPU6000_RA_ST_Y_GYRO      : constant := 16#01#;
   -- MPU6000_RA_ST_Z_GYRO      : constant := 16#02#;
   MPU6000_RA_SELF_TEST_X     : constant := 16#0D#;
   MPU6000_RA_SELF_TEST_Y     : constant := 16#0E#;
   MPU6000_RA_SELF_TEST_Z     : constant := 16#0F#;
   MPU6000_RA_SELF_TEST_A     : constant := 16#10#;   
   -- MPU6000_RA_XG_OFFS_USRH   : constant := 16#13#;
   -- MPU6000_RA_XG_OFFS_USRL   : constant := 16#14#;
   -- MPU6000_RA_YG_OFFS_USRH   : constant := 16#15#;
   -- MPU6000_RA_YG_OFFS_USRL   : constant := 16#16#;
   -- MPU6000_RA_ZG_OFFS_USRH   : constant := 16#17#;
   -- MPU6000_RA_ZG_OFFS_USRL   : constant := 16#18#;
   MPU6000_RA_SMPLRT_DIV     : constant := 16#19#;
   MPU6000_RA_CONFIG         : constant := 16#1A#;
   MPU6000_RA_GYRO_CONFIG    : constant := 16#1B#;
   MPU6000_RA_ACCEL_CONFIG   : constant := 16#1C#;
   -- MPU6000_RA_ACCEL_CONFIG_2 : constant := 16#1D#;
   -- MPU6000_RA_LP_ACCEL_ODR   : constant := 16#1E#;
   MPU6000_RA_WOM_THR        : constant := 16#1F#;

   MPU6000_RA_FIFO_EN            : constant := 16#23#;
   MPU6000_RA_I2C_MST_CTRL       : constant := 16#24#;
   MPU6000_RA_I2C_SLV0_ADDR      : constant := 16#25#;
   MPU6000_RA_I2C_SLV0_REG       : constant := 16#26#;
   MPU6000_RA_I2C_SLV0_CTRL      : constant := 16#27#;
   MPU6000_RA_I2C_SLV1_ADDR      : constant := 16#28#;
   MPU6000_RA_I2C_SLV1_REG       : constant := 16#29#;
   MPU6000_RA_I2C_SLV1_CTRL      : constant := 16#2A#;
   MPU6000_RA_I2C_SLV2_ADDR      : constant := 16#2B#;
   MPU6000_RA_I2C_SLV2_REG       : constant := 16#2C#;
   MPU6000_RA_I2C_SLV2_CTRL      : constant := 16#2D#;
   MPU6000_RA_I2C_SLV3_ADDR      : constant := 16#2E#;
   MPU6000_RA_I2C_SLV3_REG       : constant := 16#2F#;
   MPU6000_RA_I2C_SLV3_CTRL      : constant := 16#30#;
   MPU6000_RA_I2C_SLV4_ADDR      : constant := 16#31#;
   MPU6000_RA_I2C_SLV4_REG       : constant := 16#32#;
   MPU6000_RA_I2C_SLV4_DO        : constant := 16#33#;
   MPU6000_RA_I2C_SLV4_CTRL      : constant := 16#34#;
   MPU6000_RA_I2C_SLV4_DI        : constant := 16#35#;
   MPU6000_RA_I2C_MST_STATUS     : constant := 16#36#;
   MPU6000_RA_INT_PIN_CFG        : constant := 16#37#;
   MPU6000_RA_INT_ENABLE         : constant := 16#38#;
   -- MPU6000_RA_DMP_INT_STATUS     : constant := 16#39#;
   MPU6000_RA_INT_STATUS         : constant := 16#3A#;
   MPU6000_RA_ACCEL_XOUT_H       : constant := 16#3B#;
   MPU6000_RA_ACCEL_XOUT_L       : constant := 16#3C#;
   MPU6000_RA_ACCEL_YOUT_H       : constant := 16#3D#;
   MPU6000_RA_ACCEL_YOUT_L       : constant := 16#3E#;
   MPU6000_RA_ACCEL_ZOUT_H       : constant := 16#3F#;
   MPU6000_RA_ACCEL_ZOUT_L       : constant := 16#40#;
   MPU6000_RA_TEMP_OUT_H         : constant := 16#41#;
   MPU6000_RA_TEMP_OUT_L         : constant := 16#42#;
   MPU6000_RA_GYRO_XOUT_H        : constant := 16#43#;
   MPU6000_RA_GYRO_XOUT_L        : constant := 16#44#;
   MPU6000_RA_GYRO_YOUT_H        : constant := 16#45#;
   MPU6000_RA_GYRO_YOUT_L        : constant := 16#46#;
   MPU6000_RA_GYRO_ZOUT_H        : constant := 16#47#;
   MPU6000_RA_GYRO_ZOUT_L        : constant := 16#48#;
   MPU6000_RA_EXT_SENS_DATA_00   : constant := 16#49#;
   MPU6000_RA_EXT_SENS_DATA_01   : constant := 16#4A#;
   MPU6000_RA_EXT_SENS_DATA_02   : constant := 16#4B#;
   MPU6000_RA_EXT_SENS_DATA_03   : constant := 16#4C#;
   MPU6000_RA_EXT_SENS_DATA_04   : constant := 16#4D#;
   MPU6000_RA_EXT_SENS_DATA_05   : constant := 16#4E#;
   MPU6000_RA_EXT_SENS_DATA_06   : constant := 16#4F#;
   MPU6000_RA_EXT_SENS_DATA_07   : constant := 16#50#;
   MPU6000_RA_EXT_SENS_DATA_08   : constant := 16#51#;
   MPU6000_RA_EXT_SENS_DATA_09   : constant := 16#52#;
   MPU6000_RA_EXT_SENS_DATA_10   : constant := 16#53#;
   MPU6000_RA_EXT_SENS_DATA_11   : constant := 16#54#;
   MPU6000_RA_EXT_SENS_DATA_12   : constant := 16#55#;
   MPU6000_RA_EXT_SENS_DATA_13   : constant := 16#56#;
   MPU6000_RA_EXT_SENS_DATA_14   : constant := 16#57#;
   MPU6000_RA_EXT_SENS_DATA_15   : constant := 16#58#;
   MPU6000_RA_EXT_SENS_DATA_16   : constant := 16#59#;
   MPU6000_RA_EXT_SENS_DATA_17   : constant := 16#5A#;
   MPU6000_RA_EXT_SENS_DATA_18   : constant := 16#5B#;
   MPU6000_RA_EXT_SENS_DATA_19   : constant := 16#5C#;
   MPU6000_RA_EXT_SENS_DATA_20   : constant := 16#5D#;
   MPU6000_RA_EXT_SENS_DATA_21   : constant := 16#5E#;
   MPU6000_RA_EXT_SENS_DATA_22   : constant := 16#5F#;
   MPU6000_RA_EXT_SENS_DATA_23   : constant := 16#60#;
   MPU6000_RA_MOT_DETECT_STATUS  : constant := 16#61#;
   MPU6000_RA_I2C_SLV0_DO        : constant := 16#63#;
   MPU6000_RA_I2C_SLV1_DO        : constant := 16#64#;
   MPU6000_RA_I2C_SLV2_DO        : constant := 16#65#;
   MPU6000_RA_I2C_SLV3_DO        : constant := 16#66#;
   MPU6000_RA_I2C_MST_DELAY_CTRL : constant := 16#67#;
   MPU6000_RA_SIGNAL_PATH_RESET  : constant := 16#68#;
   MPU6000_RA_MOT_DETECT_CTRL    : constant := 16#69#;
   MPU6000_RA_USER_CTRL          : constant := 16#6A#;
   MPU6000_RA_PWR_MGMT_1         : constant := 16#6B#;
   MPU6000_RA_PWR_MGMT_2         : constant := 16#6C#;
   -- MPU6000_RA_BANK_SEL           : constant := 16#6D#;
   -- MPU6000_RA_MEM_START_ADDR     : constant := 16#6E#;
   -- MPU6000_RA_MEM_R_W            : constant := 16#6F#;
   -- MPU6000_RA_DMP_CFG_1          : constant := 16#70#;
   -- MPU6000_RA_DMP_CFG_2          : constant := 16#71#;
   MPU6000_RA_FIFO_COUNTH        : constant := 16#72#;
   MPU6000_RA_FIFO_COUNTL        : constant := 16#73#;
   MPU6000_RA_FIFO_R_W           : constant := 16#74#;
   MPU6000_RA_WHO_AM_I           : constant := 16#75#;

   MPU6000_RA_XA_OFFSET_H : constant := 16#77#;
   MPU6000_RA_XA_OFFSET_L : constant := 16#78#;
   MPU6000_RA_YA_OFFSET_H : constant := 16#7A#;
   MPU6000_RA_YA_OFFSET_L : constant := 16#7B#;
   MPU6000_RA_ZA_OFFSET_H : constant := 16#7D#;
   MPU6000_RA_ZA_OFFSET_L : constant := 16#7E#;




   MPU6000_TC_PWR_MODE_BIT    : constant := 7;
   MPU6000_TC_OFFSET_BIT      : constant := 6;
   MPU6000_TC_OFFSET_LENGTH   : constant := 6;
   MPU6000_TC_OTP_BNK_VLD_BIT : constant := 0;

   MPU6000_VDDIO_LEVEL_VLOGIC : constant := 0;
   MPU6000_VDDIO_LEVEL_VDD    : constant := 1;

   MPU6000_CFG_EXT_SYNC_SET_BIT    : constant := 5;
   MPU6000_CFG_EXT_SYNC_SET_LENGTH : constant := 3;
   MPU6000_CFG_DLPF_CFG_BIT        : constant := 2;
   MPU6000_CFG_DLPF_CFG_LENGTH     : constant := 3;

   MPU6000_EXT_SYNC_DISABLED     : constant := 16#0#;
   MPU6000_EXT_SYNC_TEMP_OUT_L   : constant := 16#1#;
   MPU6000_EXT_SYNC_GYRO_XOUT_L  : constant := 16#2#;
   MPU6000_EXT_SYNC_GYRO_YOUT_L  : constant := 16#3#;
   MPU6000_EXT_SYNC_GYRO_ZOUT_L  : constant := 16#4#;
   MPU6000_EXT_SYNC_ACCEL_XOUT_L : constant := 16#5#;
   MPU6000_EXT_SYNC_ACCEL_YOUT_L : constant := 16#6#;
   MPU6000_EXT_SYNC_ACCEL_ZOUT_L : constant := 16#7#;

   MPU6000_GCONFIG_XG_ST_BIT     : constant := 7;
   MPU6000_GCONFIG_YG_ST_BIT     : constant := 6;
   MPU6000_GCONFIG_ZG_ST_BIT     : constant := 5;
   MPU6000_GCONFIG_FS_SEL_BIT    : constant := 4;
   MPU6000_GCONFIG_FS_SEL_LENGTH : constant := 2;

   MPU6000_ACONFIG_XA_ST_BIT        : constant := 7;
   MPU6000_ACONFIG_YA_ST_BIT        : constant := 6;
   MPU6000_ACONFIG_ZA_ST_BIT        : constant := 5;
   MPU6000_ACONFIG_AFS_SEL_BIT      : constant := 4;
   MPU6000_ACONFIG_AFS_SEL_LENGTH   : constant := 2;
   MPU6000_ACONFIG_ACCEL_HPF_BIT    : constant := 2;
   MPU6000_ACONFIG_ACCEL_HPF_LENGTH : constant := 3;

   MPU6000_DHPF_RESET : constant := 16#00#;
   MPU6000_DHPF_5     : constant := 16#01#;
   MPU6000_DHPF_2P5   : constant := 16#02#;
   MPU6000_DHPF_1P25  : constant := 16#03#;
   MPU6000_DHPF_0P63  : constant := 16#04#;
   MPU6000_DHPF_HOLD  : constant := 16#07#;

   MPU6000_TEMP_FIFO_EN_BIT  : constant := 7;
   MPU6000_XG_FIFO_EN_BIT    : constant := 6;
   MPU6000_YG_FIFO_EN_BIT    : constant := 5;
   MPU6000_ZG_FIFO_EN_BIT    : constant := 4;
   MPU6000_ACCEL_FIFO_EN_BIT : constant := 3;
   MPU6000_SLV2_FIFO_EN_BIT  : constant := 2;
   MPU6000_SLV1_FIFO_EN_BIT  : constant := 1;
   MPU6000_SLV0_FIFO_EN_BIT  : constant := 0;

   MPU6000_MULT_MST_EN_BIT    : constant := 7;
   MPU6000_WAIT_FOR_ES_BIT    : constant := 6;
   MPU6000_SLV_3_FIFO_EN_BIT  : constant := 5;
   MPU6000_I2C_MST_P_NSR_BIT  : constant := 4;
   MPU6000_I2C_MST_CLK_BIT    : constant := 3;
   MPU6000_I2C_MST_CLK_LENGTH : constant := 4;

   MPU6000_CLOCK_DIV_348 : constant := 16#0#;
   MPU6000_CLOCK_DIV_333 : constant := 16#1#;
   MPU6000_CLOCK_DIV_320 : constant := 16#2#;
   MPU6000_CLOCK_DIV_308 : constant := 16#3#;
   MPU6000_CLOCK_DIV_296 : constant := 16#4#;
   MPU6000_CLOCK_DIV_286 : constant := 16#5#;
   MPU6000_CLOCK_DIV_276 : constant := 16#6#;
   MPU6000_CLOCK_DIV_267 : constant := 16#7#;
   MPU6000_CLOCK_DIV_258 : constant := 16#8#;
   MPU6000_CLOCK_DIV_500 : constant := 16#9#;
   MPU6000_CLOCK_DIV_471 : constant := 16#A#;
   MPU6000_CLOCK_DIV_444 : constant := 16#B#;
   MPU6000_CLOCK_DIV_421 : constant := 16#C#;
   MPU6000_CLOCK_DIV_400 : constant := 16#D#;
   MPU6000_CLOCK_DIV_381 : constant := 16#E#;
   MPU6000_CLOCK_DIV_364 : constant := 16#F#;

   MPU6000_I2C_SLV_RW_BIT      : constant := 7;
   MPU6000_I2C_SLV_ADDR_BIT    : constant := 6;
   MPU6000_I2C_SLV_ADDR_LENGTH : constant := 7;
   MPU6000_I2C_SLV_EN_BIT      : constant := 7;
   MPU6000_I2C_SLV_BYTE_SW_BIT : constant := 6;
   MPU6000_I2C_SLV_REG_DIS_BIT : constant := 5;
   MPU6000_I2C_SLV_GRP_BIT     : constant := 4;
   MPU6000_I2C_SLV_LEN_BIT     : constant := 3;
   MPU6000_I2C_SLV_LEN_LENGTH  : constant := 4;

   MPU6000_I2C_SLV4_RW_BIT         : constant := 7;
   MPU6000_I2C_SLV4_ADDR_BIT       : constant := 6;
   MPU6000_I2C_SLV4_ADDR_LENGTH    : constant := 7;
   MPU6000_I2C_SLV4_EN_BIT         : constant := 7;
   MPU6000_I2C_SLV4_INT_EN_BIT     : constant := 6;
   MPU6000_I2C_SLV4_REG_DIS_BIT    : constant := 5;
   MPU6000_I2C_SLV4_MST_DLY_BIT    : constant := 4;
   MPU6000_I2C_SLV4_MST_DLY_LENGTH : constant := 5;

   MPU6000_MST_PASS_THROUGH_BIT  : constant := 7;
   MPU6000_MST_I2C_SLV4_DONE_BIT : constant := 6;
   MPU6000_MST_I2C_LOST_ARB_BIT  : constant := 5;
   MPU6000_MST_I2C_SLV4_NACK_BIT : constant := 4;
   MPU6000_MST_I2C_SLV3_NACK_BIT : constant := 3;
   MPU6000_MST_I2C_SLV2_NACK_BIT : constant := 2;
   MPU6000_MST_I2C_SLV1_NACK_BIT : constant := 1;
   MPU6000_MST_I2C_SLV0_NACK_BIT : constant := 0;

   MPU6000_INTCFG_INT_LEVEL_BIT       : constant := 7;
   MPU6000_INTCFG_INT_OPEN_BIT        : constant := 6;
   MPU6000_INTCFG_LATCH_INT_EN_BIT    : constant := 5;
   MPU6000_INTCFG_INT_RD_CLEAR_BIT    : constant := 4;
   MPU6000_INTCFG_FSYNC_INT_LEVEL_BIT : constant := 3;
   MPU6000_INTCFG_FSYNC_INT_EN_BIT    : constant := 2;
   MPU6000_INTCFG_I2C_BYPASS_EN_BIT   : constant := 1;
   MPU6000_INTCFG_CLKOUT_EN_BIT       : constant := 0;

   MPU6000_INTMODE_ACTIVEHIGH : constant := 16#00#;
   MPU6000_INTMODE_ACTIVELOW  : constant := 16#01#;

   MPU6000_INTDRV_PUSHPULL  : constant := 16#00#;
   MPU6000_INTDRV_OPENDRAIN : constant := 16#01#;

   MPU6000_INTLATCH_50USPULSE : constant := 16#00#;
   MPU6000_INTLATCH_WAITCLEAR : constant := 16#01#;

   MPU6000_INTCLEAR_STATUSREAD : constant := 16#00#;
   MPU6000_INTCLEAR_ANYREAD    : constant := 16#01#;

   MPU6000_INTERRUPT_FF_BIT          : constant := 7;
   MPU6000_INTERRUPT_MOT_BIT         : constant := 6;
   MPU6000_INTERRUPT_ZMOT_BIT        : constant := 5;
   MPU6000_INTERRUPT_FIFO_OFLOW_BIT  : constant := 4;
   MPU6000_INTERRUPT_I2C_MST_INT_BIT : constant := 3;
   MPU6000_INTERRUPT_PLL_RDY_INT_BIT : constant := 2;
   MPU6000_INTERRUPT_DMP_INT_BIT     : constant := 1;
   MPU6000_INTERRUPT_DATA_RDY_BIT    : constant := 0;

   MPU6000_DMPINT_5_BIT : constant := 5;
   MPU6000_DMPINT_4_BIT : constant := 4;
   MPU6000_DMPINT_3_BIT : constant := 3;
   MPU6000_DMPINT_2_BIT : constant := 2;
   MPU6000_DMPINT_1_BIT : constant := 1;
   MPU6000_DMPINT_0_BIT : constant := 0;

   MPU6000_MOTION_MOT_XNEG_BIT  : constant := 7;
   MPU6000_MOTION_MOT_XPOS_BIT  : constant := 6;
   MPU6000_MOTION_MOT_YNEG_BIT  : constant := 5;
   MPU6000_MOTION_MOT_YPOS_BIT  : constant := 4;
   MPU6000_MOTION_MOT_ZNEG_BIT  : constant := 3;
   MPU6000_MOTION_MOT_ZPOS_BIT  : constant := 2;
   MPU6000_MOTION_MOT_ZRMOT_BIT : constant := 0;

   MPU6000_DELAYCTRL_DELAY_ES_SHADOW_BIT : constant := 7;
   MPU6000_DELAYCTRL_I2C_SLV4_DLY_EN_BIT : constant := 4;
   MPU6000_DELAYCTRL_I2C_SLV3_DLY_EN_BIT : constant := 3;
   MPU6000_DELAYCTRL_I2C_SLV2_DLY_EN_BIT : constant := 2;
   MPU6000_DELAYCTRL_I2C_SLV1_DLY_EN_BIT : constant := 1;
   MPU6000_DELAYCTRL_I2C_SLV0_DLY_EN_BIT : constant := 0;

   MPU6000_PATHRESET_GYRO_RESET_BIT  : constant := 2;
   MPU6000_PATHRESET_ACCEL_RESET_BIT : constant := 1;
   MPU6000_PATHRESET_TEMP_RESET_BIT  : constant := 0;

   MPU6000_DETECT_ACCEL_ON_DELAY_BIT    : constant := 5;
   MPU6000_DETECT_ACCEL_ON_DELAY_LENGTH : constant := 2;
   MPU6000_DETECT_FF_COUNT_BIT          : constant := 3;
   MPU6000_DETECT_FF_COUNT_LENGTH       : constant := 2;
   MPU6000_DETECT_MOT_COUNT_BIT         : constant := 1;
   MPU6000_DETECT_MOT_COUNT_LENGTH      : constant := 2;

   MPU6000_DETECT_DECREMENT_RESET : constant := 16#0#;
   MPU6000_DETECT_DECREMENT_1     : constant := 16#1#;
   MPU6000_DETECT_DECREMENT_2     : constant := 16#2#;
   MPU6000_DETECT_DECREMENT_4     : constant := 16#3#;

   MPU6000_USERCTRL_DMP_EN_BIT         : constant := 7;
   MPU6000_USERCTRL_FIFO_EN_BIT        : constant := 6;
   MPU6000_USERCTRL_I2C_MST_EN_BIT     : constant := 5;
   MPU6000_USERCTRL_I2C_IF_DIS_BIT     : constant := 4;
   MPU6000_USERCTRL_DMP_RESET_BIT      : constant := 3;
   MPU6000_USERCTRL_FIFO_RESET_BIT     : constant := 2;
   MPU6000_USERCTRL_I2C_MST_RESET_BIT  : constant := 1;
   MPU6000_USERCTRL_SIG_COND_RESET_BIT : constant := 0;

   MPU6000_PWR1_DEVICE_RESET_BIT : constant := 7;
   MPU6000_PWR1_SLEEP_BIT        : constant := 6;
   MPU6000_PWR1_CYCLE_BIT        : constant := 5;
   MPU6000_PWR1_TEMP_DIS_BIT     : constant := 3;
   MPU6000_PWR1_CLKSEL_BIT       : constant := 2;
   MPU6000_PWR1_CLKSEL_LENGTH    : constant := 3;

   MPU6000_CLOCK_INTERNAL   : constant := 16#00#;
   MPU6000_CLOCK_PLL_XGYRO  : constant := 16#01#;
   MPU6000_CLOCK_PLL_YGYRO  : constant := 16#02#;
   MPU6000_CLOCK_PLL_ZGYRO  : constant := 16#03#;
   MPU6000_CLOCK_PLL_EXT32K : constant := 16#04#;
   MPU6000_CLOCK_PLL_EXT19M : constant := 16#05#;
   MPU6000_CLOCK_KEEP_RESET : constant := 16#07#;

   MPU6000_PWR2_LP_WAKE_CTRL_BIT    : constant := 7;
   MPU6000_PWR2_LP_WAKE_CTRL_LENGTH : constant := 2;
   MPU6000_PWR2_STBY_XA_BIT         : constant := 5;
   MPU6000_PWR2_STBY_YA_BIT         : constant := 4;
   MPU6000_PWR2_STBY_ZA_BIT         : constant := 3;
   MPU6000_PWR2_STBY_XG_BIT         : constant := 2;
   MPU6000_PWR2_STBY_YG_BIT         : constant := 1;
   MPU6000_PWR2_STBY_ZG_BIT         : constant := 0;

   MPU6000_WAKE_FREQ_1P25 : constant := 16#0#;
   MPU6000_WAKE_FREQ_2P5  : constant := 16#1#;
   MPU6000_WAKE_FREQ_5    : constant := 16#2#;
   MPU6000_WAKE_FREQ_10   : constant := 16#3#;

   MPU6000_BANKSEL_PRFTCH_EN_BIT     : constant := 6;
   MPU6000_BANKSEL_CFG_USER_BANK_BIT : constant := 5;
   MPU6000_BANKSEL_MEM_SEL_BIT       : constant := 4;
   MPU6000_BANKSEL_MEM_SEL_LENGTH    : constant := 5;

   MPU6000_WHO_AM_I_BIT    : constant := 6;
   MPU6000_WHO_AM_I_LENGTH : constant := 6;

   MPU6000_DMP_MEMORY_BANKS      : constant := 8;
   MPU6000_DMP_MEMORY_BANK_SIZE  : constant := 256;
   MPU6000_DMP_MEMORY_CHUNK_SIZE : constant := 16;

   MPU6000_ST_GYRO_LOW           : constant := (-14.0);
   MPU6000_ST_GYRO_HIGH          : constant := 14.0;
   MPU6000_ST_ACCEL_LOW          : constant := (-14.0);
   MPU6000_ST_ACCEL_HIGH         : constant := 14.0;

   MPU6000_ST_TB : constant Unsigned_16_Array (1 .. 256)
     := (
         2620, 2646, 2672, 2699, 2726, 2753, 2781, 2808,
         2837, 2865, 2894, 2923, 2952, 2981, 3011, 3041,
         3072, 3102, 3133, 3165, 3196, 3228, 3261, 3293,
         3326, 3359, 3393, 3427, 3461, 3496, 3531, 3566,
         3602, 3638, 3674, 3711, 3748, 3786, 3823, 3862,
         3900, 3939, 3979, 4019, 4059, 4099, 4140, 4182,
         4224, 4266, 4308, 4352, 4395, 4439, 4483, 4528,
         4574, 4619, 4665, 4712, 4759, 4807, 4855, 4903,
         4953, 5002, 5052, 5103, 5154, 5205, 5257, 5310,
         5363, 5417, 5471, 5525, 5581, 5636, 5693, 5750,
         5807, 5865, 5924, 5983, 6043, 6104, 6165, 6226,
         6289, 6351, 6415, 6479, 6544, 6609, 6675, 6742,
         6810, 6878, 6946, 7016, 7086, 7157, 7229, 7301,
         7374, 7448, 7522, 7597, 7673, 7750, 7828, 7906,
         7985, 8065, 8145, 8227, 8309, 8392, 8476, 8561,
         8647, 8733, 8820, 8909, 8998, 9088, 9178, 9270,
         9363, 9457, 9551, 9647, 9743, 9841, 9939, 10038,
         10139, 10240, 10343, 10446, 10550, 10656, 10763, 10870,
         10979, 11089, 11200, 11312, 11425, 11539, 11654, 11771,
         11889, 12008, 12128, 12249, 12371, 12495, 12620, 12746,
         12874, 13002, 13132, 13264, 13396, 13530, 13666, 13802,
         13940, 14080, 14221, 14363, 14506, 14652, 14798, 14946,
         15096, 15247, 15399, 15553, 15709, 15866, 16024, 16184,
         16346, 16510, 16675, 16842, 17010, 17180, 17352, 17526,
         17701, 17878, 18057, 18237, 18420, 18604, 18790, 18978,
         19167, 19359, 19553, 19748, 19946, 20145, 20347, 20550,
         20756, 20963, 21173, 21385, 21598, 21814, 22033, 22253,
         22475, 22700, 22927, 23156, 23388, 23622, 23858, 24097,
         24338, 24581, 24827, 25075, 25326, 25579, 25835, 26093,
         26354, 26618, 26884, 27153, 27424, 27699, 27976, 28255,
         28538, 28823, 29112, 29403, 29697, 29994, 30294, 30597,
         30903, 31212, 31524, 31839, 32157, 32479, 32804, 33132
        );

end MPU6000.Register;
