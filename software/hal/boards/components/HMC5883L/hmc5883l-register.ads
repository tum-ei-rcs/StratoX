
-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: register definitions for the HMC5883L

package HMC5883L.Register with SPARK_Mode is

   HMC5883L_ADDRESS : constant := 16#3C# ;-- this device only has one address
   HMC5883L_DEFAULT_ADDRESS : constant := 16#1E#;  -- 2#0011_110X

   HMC5883L_RA_CONFIG_A : constant := 16#00#;
   HMC5883L_RA_CONFIG_B : constant := 16#01#;
   HMC5883L_RA_MODE : constant := 16#02#;
   HMC5883L_RA_DATAX_H : constant := 16#03#;
   HMC5883L_RA_DATAX_L : constant := 16#04#;
   HMC5883L_RA_DATAZ_H : constant := 16#05#;
   HMC5883L_RA_DATAZ_L : constant := 16#06#;
   HMC5883L_RA_DATAY_H : constant := 16#07#;
   HMC5883L_RA_DATAY_L : constant := 16#08#;
   HMC5883L_RA_STATUS : constant := 16#09#;
   HMC5883L_RA_IDA : constant := 16#0A#;
   HMC5883L_RA_IDB : constant := 16#0B#;
   HMC5883L_RA_IDC : constant := 16#0C#;

   HMC5883L_CRA_AVERAGE_BIT : constant := 6;
   HMC5883L_CRA_AVERAGE_LENGTH : constant := 2;
   HMC5883L_CRA_RATE_BIT : constant := 4;
   HMC5883L_CRA_RATE_LENGTH : constant := 3;
   HMC5883L_CRA_BIAS_BIT : constant := 1;
   HMC5883L_CRA_BIAS_LENGTH : constant := 2;

   HMC5883L_AVERAGING_1 : constant := 16#00#;
   HMC5883L_AVERAGING_2 : constant := 16#01#;
   HMC5883L_AVERAGING_4 : constant := 16#02#;
   HMC5883L_AVERAGING_8 : constant := 16#03#;

   HMC5883L_RATE_0P75 : constant := 16#00#;
   HMC5883L_RATE_1P5 : constant := 16#01#;
   HMC5883L_RATE_3 : constant := 16#02#;
   HMC5883L_RATE_7P5 : constant := 16#03#;
   HMC5883L_RATE_15 : constant := 16#04#;
   HMC5883L_RATE_30 : constant := 16#05#;
   HMC5883L_RATE_75 : constant := 16#06#;

   HMC5883L_BIAS_NORMAL : constant := 16#00#;
   HMC5883L_BIAS_POSITIVE : constant := 16#01#;
   HMC5883L_BIAS_NEGATIVE : constant := 16#02#;

   HMC5883L_CRB_GAIN_BIT : constant := 7;
   HMC5883L_CRB_GAIN_LENGTH : constant := 3;

   HMC5883L_GAIN_1370 : constant := 16#00#;
   HMC5883L_GAIN_1090 : constant := 16#01#;
   HMC5883L_GAIN_820 : constant := 16#02#;
   HMC5883L_GAIN_660 : constant := 16#03#;
   HMC5883L_GAIN_440 : constant := 16#04#;
   HMC5883L_GAIN_390 : constant := 16#05#;
   HMC5883L_GAIN_330 : constant := 16#06#;
   HMC5883L_GAIN_220 : constant := 16#07#;

   HMC5883L_MODEREG_BIT : constant := 1;
   HMC5883L_MODEREG_LENGTH : constant := 2;

   HMC5883L_MODE_CONTINUOUS : constant := 16#00#;
   HMC5883L_MODE_SINGLE : constant := 16#01#;
   HMC5883L_MODE_IDLE : constant := 16#02#;

   HMC5883L_STATUS_LOCK_BIT : constant := 1;
   HMC5883L_STATUS_READY_BIT : constant := 0;

end HMC5883L.Register;
