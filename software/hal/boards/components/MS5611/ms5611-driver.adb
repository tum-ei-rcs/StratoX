--
with Units;
with Units.Operations; use Units.Operations;
use type Units.Unit_Type;
with HIL.SPI;   -- Hardware Interface to SPI
with MS5611.Register; use MS5611.Register;
with Ada.Real_Time; use Ada.Real_Time;

package body MS5611.Driver with 
SPARK_Mode,
Refined_State => (State => (G_Baro_State, temperature_raw, temperature, pressure_raw, pressure),
                  Coefficients => (G_sens_t1, G_off_t1, G_tcs, G_tco, G_t_ref, G_tempsens, dT, SENS, OFF, TEMP))
is

   type Data_Array is array (Natural range <>) of HIL.Byte with
        Component_Size => 8;

   -- baro device states
   type Baro_FSM_Type is
     (NOT_INITIALIZED, READY, TEMPERATURE_CONVERSION, PRESSURE_CONVERSION) with Default_Value => NOT_INITIALIZED;

   type Conversion_Info_Type is record
      OSR   : OSR_Type;
      Start : Time_Type;
   end record;

   -- the current state of the sensor device
   -- @field FSM_State what the device is currently doing
   -- @field Conv_Info_Temp context for state TEMPERATURE_CONVERSION
   -- @field Conv_Info_Pres context for state PRESSURE_CONVERSION
   type Baro_State_Type is record
      FSM_State      : Baro_FSM_Type;
      Conv_Info_Temp : Conversion_Info_Type;
      Conv_Info_Pres : Conversion_Info_Type;
   end record;

   type Conversion_Time_LUT_Type is array (OSR_Type) of Time_Type;

   type Coefficient_ID_Type is (COEFF_SENS_T1, COEFF_OFF_T1, COEFF_TCS, COEFF_TCO, COEFF_T_REF, COEFF_TEMPSENS);
   type Coefficient_Data_Type is mod 2**16 with
        Size => 16;

   type Conversion_ID_Type is (D1, D2);
   type Conversion_Data_Type is mod 2**24 with Size => 24;

   
   subtype Sens_T1_Type is Float range 0.0 .. Float((2**16 - 1) * 2**15);
   subtype Off_T1_Type is Float range 0.0 .. Float((2**16 - 1) * 2**16);
   subtype TCS_Type is Float range 0.0 .. Float(2**16 - 1) / Float(2**8);
   subtype TCO_Type is Float range 0.0 .. Float(2**16 - 1) / Float(2**7);
   subtype T_Ref_Type is Float range 0.0 .. Float((2**16 - 1) * 2**8);
   subtype Tempsens_Type is Float range 0.0 .. Float(2**16 - 1) / Float(2**23);


   subtype DT_Type is Float range -16776960.9 .. 16777216.9;
   subtype Sense_Type is Float range -4294836225.9 .. 6442352640.9;
   subtype OFF_Type is Float range -8589672450.9 .. 12884705280.9;
   subtype TEMP_Type is Float range -4000.9 .. 8500.9;

   --  a bunch of functions that allows to add/sub/cast types without range problems
   function Sat_Cast_Tref is new Units.Saturated_Cast (T_Ref_Type);
   function Sat_Cast_Tempsense is new Units.Saturated_Cast (Tempsens_Type);
   function Sat_Cast_TCO is new Units.Saturated_Cast (TCO_Type);
   function Sat_Cast_TCS is new Units.Saturated_Cast (TCS_Type);
   function Sat_Cast_OffType is new Units.Saturated_Cast (OFF_Type);
   function Sat_Cast_TEMPType is new Units.Saturated_Cast (TEMP_Type);
   function Sat_Cast_SensType is new Units.Saturated_Cast (Sense_Type);
   
   function Sat_Add_OffType is new Units.Saturated_Addition (OFF_Type);
   function Sat_Add_SensType is new Units.Saturated_Addition (Sense_Type);
   function Sat_Add_TempType is new Units.Saturated_Addition (TEMP_Type);
   
   function Sat_Sub_TempType is new Units.Saturated_Subtraction (TEMP_Type);
   function Sat_Sub_OffType is new Units.Saturated_Subtraction (OFF_Type);
   function Sat_Sub_SensType is new Units.Saturated_Subtraction (Sense_Type);
   
   ----------------------
   --  PROTOTYPES
   ----------------------

   procedure start_conversion (ID : Conversion_ID_Type; OSR : OSR_Type);
   function calculateTemperatureDifference
     (Temp_Raw : Conversion_Data_Type;
      T_Ref    : Float) return DT_Type;

   procedure compensateTemperature;

   function conversion_Finished(state : Baro_State_Type;
                                conv_time : Conversion_Time_LUT_Type;
                                now : Time) return Boolean;

   function convertToKelvin (thisTemp : in TEMP_Type) return Temperature_Type;

   function calculatePressure
     (arg_pressure_raw : Conversion_Data_Type;
      arg_sense        : Sense_Type;
      arg_offset       : OFF_Type) return Pressure_Type;
   --  calculate physical pressure from raw measurements
   --  @param arg_pressure_raw raw pressure data
   --  @param arg_sense raw sense data
   --  @param arg_offset calibration offset
   --  @return barometric pressure

   --  maximum conversion times (taken from the datasheet)
   Conversion_Time_LUT : constant Conversion_Time_LUT_Type :=
     (OSR_256  => Time_Type (0.60 / 1000.0),
      OSR_512  => Time_Type (1.17 / 1000.0),
      OSR_1024 => Time_Type (2.28 / 1000.0),
      OSR_2048 => Time_Type (4.54 / 1000.0),
      OSR_4096 => Time_Type (9.04 / 1000.0));

   --  conversion variables
   G_Baro_State : Baro_State_Type :=
     (FSM_State      => NOT_INITIALIZED,
      Conv_Info_Temp => (OSR_256, Time_Type (0.0)),
      Conv_Info_Pres => (OSR_256, Time_Type (0.0)));

   --  calibration variables (read values)
   G_sens_t1  : Sens_T1_Type := 0.0;  -- Pressure sensitivity (54487)
   G_off_t1   : Off_T1_Type := 0.0;  -- Pressure offset (51552)
   G_tcs      : TCS_Type := 0.0;  -- Temperature coefficient of pressure sensitivity (33258)
   G_tco      : TCO_Type := 0.0;  -- Temperature coefficient of pressure offset (27255)
   G_t_ref    : T_Ref_Type := 0.0;  -- barometer reference temperature (29426)
   G_tempsens : Tempsens_Type := 0.0;  -- Temperature coefficient of the temperature (27777)

   --  ADC values
   temperature_raw : Conversion_Data_Type := 0;  -- raw temperture read from baro
   pressure_raw : Conversion_Data_Type := 0;  -- raw pressure read from baro

   --  Compensation values
   dT : DT_Type := 0.0; -- difference between actual and reference temperature
   SENS : Sense_Type := 0.0; -- pressure sensitivity at the actual temperature
   OFF  : OFF_Type   := 0.0; -- pressure offset at actual temperature

   TEMP : TEMP_Type := 0.0;

   --  final measurement values
   pressure : Pressure_Type := 101300.0 * Units.Pascal;  -- invalid initial value
   temperature : Temperature_Type := 293.15 * Units.Kelvin;

   G_CELSIUS_0 : constant := 273.15;

   -- Glue Code
   -- the following procedures access the Hardware Interface Layer (HIL)
   

   ----------------------
   --  selectDevice
   ----------------------
   
   procedure selectDevice (Device : Device_Type) is
   begin
      if Device = Baro then
         HIL.SPI.select_Chip (HIL.SPI.Barometer);
      end if;
   end selectDevice;

   ----------------------
   --  deselectDevice
   ----------------------
   
   procedure deselectDevice (Device : Device_Type) is
   begin
      if Device = Baro then
         HIL.SPI.deselect_Chip (HIL.SPI.Barometer);
      end if;
   end deselectDevice;

   ----------------------
   --  writeToDevice
   ----------------------
   
   procedure writeToDevice (Device : Device_Type; data : in Data_Array) is
   begin
      selectDevice (Device);
      HIL.SPI.write (HIL.SPI.Barometer, HIL.SPI.Data_Type (data));
      deselectDevice (Device);
   end writeToDevice;
   
   ----------------------
   --  transferWithDevice
   ----------------------
   
   procedure transferWithDevice
     (Device  :        Device_Type;
      data_tx : in     Data_Array;
      data_rx :    out Data_Array)
   is
   begin
      selectDevice (Device);
      HIL.SPI.transceive
        (HIL.SPI.Barometer,
         HIL.SPI.Data_Type (data_tx),
         HIL.SPI.Data_Type (data_rx));
      deselectDevice (Device);
   end transferWithDevice;

--     -- This is where the magic occurs.
--     Function Convert( Data : In Data_Array ) Return Coefficient_Data_Type is
--        Result : Coefficient_Data_Type;
--        For Result'Address use Data'Address;
--        Pragma Import( Convention => Ada, Entity => Result );
--        Pragma Inline( Convert );
--     begin
--        Return Result;
--     end Convert;

   ----------------------
   --  read_coefficient
   ----------------------
   
   -- reads a PROM coefficient value
   procedure read_coefficient
     (Device     :     Device_Type;
      coeff_id   :     Coefficient_ID_Type;
      coeff_data : out Coefficient_Data_Type)
   is
      Data_TX : Data_Array (1 .. 3) := (others => 0);
      Data_RX : Data_Array (1 .. 3);
   begin
      case coeff_id is
         when COEFF_SENS_T1 =>
            Data_TX (1) := HIL.Byte (CMD_READ_C1);
         when COEFF_OFF_T1 =>
            Data_TX (1) := HIL.Byte (CMD_READ_C2);
         when COEFF_TCS =>
            Data_TX (1) := HIL.Byte (CMD_READ_C3);
         when COEFF_TCO =>
            Data_TX (1) := HIL.Byte (CMD_READ_C4);
         when COEFF_T_REF =>
            Data_TX (1) := HIL.Byte (CMD_READ_C5);
         when COEFF_TEMPSENS =>
            Data_TX (1) := HIL.Byte (CMD_READ_C6);
      end case;

      transferWithDevice (Device, Data_TX, Data_RX);
      coeff_data :=
        Coefficient_Data_Type (Data_RX (3)) +
        Coefficient_Data_Type (Data_RX (2)) * (2**8);
      -- coeff_data := Convert( data(1 .. 2) );
   end read_coefficient;

   ----------------------
   --  read_adc
   ----------------------
   
   --  reads the 24 bit ADC value from the barometer
   procedure read_adc (Device : Device_Type; adc_value : out Conversion_Data_Type) 
   is
      Data_TX : constant Data_Array (1 .. 4) :=
        (1 => HIL.Byte (CMD_ADC_READ), others => 0);
      Data_RX : Data_Array (1 .. 4);
   begin
      transferWithDevice (Device, Data_TX, Data_RX);
      adc_value :=
        Conversion_Data_Type (Data_RX (4)) +
        Conversion_Data_Type (Data_RX (3)) * (2**8) +
        Conversion_Data_Type (Data_RX (2)) * (2**16);
   end read_adc;

   ----------------------
   --  reset
   ----------------------
   
   procedure reset is
   begin
      writeToDevice (Baro, (1 => HIL.Byte (CMD_RESET)));
   end reset;

   --  This function sequentially initializes the barometer.
   --  Therefore, the barometer is reset, the PROM-Coefficients are read and the starting-height (altitude_offset) is calculated.
   procedure init is
      c1 : Coefficient_Data_Type;
      c2 : Coefficient_Data_Type;
      c3 : Coefficient_Data_Type;
      c4 : Coefficient_Data_Type;
      c5 : Coefficient_Data_Type;
      c6 : Coefficient_Data_Type;            
   begin
      read_coefficient (Baro, COEFF_SENS_T1, c1);
      G_sens_t1 := Float (c1) * Float (2**15);

      read_coefficient (Baro, COEFF_OFF_T1, c2);
      G_off_t1 := Float (c2) * Float (2**16);

      read_coefficient (Baro, COEFF_TCS, c3);
      G_tcs := Sat_Cast_TCS (Float (c3) / Float (2**8));

      read_coefficient (Baro, COEFF_TCO, c4);
      G_tco := Sat_Cast_TCO (Float (c4) / Float (2**7));

      read_coefficient (Baro, COEFF_T_REF, c5);
      G_t_ref := Sat_Cast_Tref (Float (c5) * Float (2**8));

      read_coefficient (Baro, COEFF_TEMPSENS, c6);
      G_tempsens := Sat_Cast_Tempsense (Float (c6) / Float (2**23));

      G_Baro_State.FSM_State := READY;

   end init;
   

   ----------------------
   --  start_conversion
   ----------------------
   
   procedure start_conversion (ID : Conversion_ID_Type; OSR : OSR_Type) is
      data : Data_Array (1 .. 1) := (others => 0);
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      case (ID) is
         when D1 =>
            case (OSR) is
               when OSR_256 =>
                  data (1) := HIL.Byte (CMD_D1_CONV_256);
               when OSR_512 =>
                  data (1) := HIL.Byte (CMD_D1_CONV_512);
               when OSR_1024 =>
                  data (1) := HIL.Byte (CMD_D1_CONV_1024);
               when OSR_2048 =>
                  data (1) := HIL.Byte (CMD_D1_CONV_2048);
               when OSR_4096 =>
                  data (1) := HIL.Byte (CMD_D1_CONV_4096);
            end case;
            G_Baro_State.Conv_Info_Pres.OSR := OSR;
            G_Baro_State.Conv_Info_Pres.Start := Units.To_Time( now );
         when D2 =>
            case (OSR) is
               when OSR_256 =>
                  data (1) := HIL.Byte (CMD_D2_CONV_256);
               when OSR_512 =>
                  data (1) := HIL.Byte (CMD_D2_CONV_512);
               when OSR_1024 =>
                  data (1) := HIL.Byte (CMD_D2_CONV_1024);
               when OSR_2048 =>
                  data (1) := HIL.Byte (CMD_D2_CONV_2048);
               when OSR_4096 =>
                  data (1) := HIL.Byte (CMD_D2_CONV_4096);
            end case;
            G_Baro_State.Conv_Info_Temp.OSR := OSR;
            G_Baro_State.Conv_Info_Temp.Start := Units.To_Time( now );
      end case;
      writeToDevice (Baro, data);

   end start_conversion;

   ----------------------
   --  self_check
   ----------------------
   
   procedure self_check (Status : out Error_Type) is
      c3 : Coefficient_Data_Type;
   begin
      -- check if initialized
--        if G_Baro_State.FSM_State /= READY then
--           Status := FAILURE;
--        end if;

      -- read coefficient again and check equality
      read_coefficient (Baro, COEFF_SENS_T1, c3);
      if Float (c3) /= G_tcs then
         Status := FAILURE;
      else
         -- read D2
         start_conversion (D2, OSR_256);

         -- todo check
         Status := SUCCESS;
      end if;
   end self_check;

   ----------------------
   --  conversion_Finished
   ----------------------
   
   function conversion_Finished(state     : Baro_State_Type;
                                conv_time : Conversion_Time_LUT_Type;
                                now       : Time) return Boolean
   is
      result : Boolean;
   begin
      case(state.FSM_State) is
         when TEMPERATURE_CONVERSION =>
            result := ( Sum_Time (state.Conv_Info_Temp.Start, conv_time(state.Conv_Info_Temp.OSR)) < Units.To_Time( now) );
         when PRESSURE_CONVERSION =>
            result := ( Sum_Time (state.Conv_Info_Pres.Start, conv_time(state.Conv_Info_Pres.OSR)) < Units.To_Time( now) );
         when others =>
            result := False;
      end case;
      return result;
   end conversion_Finished;

   ------------------------------------
   --  calculateTemperatureDifference
   ------------------------------------
   
   function calculateTemperatureDifference
     (Temp_Raw : Conversion_Data_Type;
      T_Ref    : Float) return DT_Type
   is
   begin
      return DT_Type (Float (Temp_Raw) - T_Ref);
   end calculateTemperatureDifference;

   ----------------------
   --  convertToKelvin
   ----------------------
   
   function convertToKelvin (thisTemp : in TEMP_Type) return Temperature_Type is
   begin
      return Temperature_Type (G_CELSIUS_0 + thisTemp / 100.0);  -- SPARK Range Check might fail
   end convertToKelvin;

   ---------------------------
   --  compensateTemperature
   ---------------------------
   
   -- compensates values according to datasheet
   procedure compensateTemperature is
      T2    : TEMP_Type  := 0.0;
      OFF2  : OFF_Type   := 0.0;
      SENS2 : Sense_Type := 0.0;            
   begin
      if TEMP < TEMP_Type (2000.0) then
         T2    := Sat_Cast_TEMPType (dT**2 / Float (2**31));
         OFF2  := Sat_Cast_OffType (5.0 * (TEMP - TEMP_Type (2000.0))**2 / 2.0);
         SENS2 := Sense_Type (OFF2 / 2.0);

         if TEMP < TEMP_Type (-1500.0) then
            OFF2  := Sat_Add_OffType (OFF2, Sat_Cast_OffType (7.0 * (TEMP - TEMP_Type (1500.0))**2));
            SENS2 := Sat_Add_SensType (SENS2, Sat_Cast_SensType (11.0 * (TEMP - TEMP_Type (1500.0))**2 / 2.0));
         end if;
      end if;
      TEMP := Sat_Sub_TempType (TEMP, T2);    -- this compensates the final temperature value
      OFF  := Sat_Sub_OffType (OFF, OFF2);
      SENS := Sat_Sub_SensType (SENS, SENS2);
   end compensateTemperature;

   ----------------------
   --  calculatePressure
   ----------------------
   
   function calculatePressure
     (arg_pressure_raw : Conversion_Data_Type;
      arg_sense        : Sense_Type;
      arg_offset       : OFF_Type) return Pressure_Type
   is
   begin
      return Pressure_Type
          ((Float (arg_pressure_raw) * arg_sense / Float (2**21) - arg_offset) /
           Float (2**15));
   end calculatePressure;

   ----------------------
   --  get_temperature
   ----------------------
   
   function get_temperature return Temperature_Type is
   begin
      return temperature;
   end get_temperature;

   ----------------------
   --  get_pressure
   ----------------------
   
   function get_pressure return Pressure_Type is
   begin
      return pressure;
   end get_pressure;

   ----------------------
   --  update_val
   ----------------------
   
   procedure update_val is
   begin
      -- Barometer takes 10ms (8.2ms) for one conversion, barometer_update_val gets called every main_loop (5ms)
      -- read conversion value every second to make sure barometer timing constraint is not violated
      case G_Baro_State.FSM_State is

         when NOT_INITIALIZED =>
            null;

         when READY =>
            start_conversion (D2, OSR_4096);
            G_Baro_State.FSM_State := TEMPERATURE_CONVERSION;

         when TEMPERATURE_CONVERSION =>
            -- ToDo check time
            declare
               t_abs : Ada.Real_Time.Time := Clock; -- see SPARK RM 7.1.3-12 (Clock cannot be a direct parameter)               
            begin
               if conversion_Finished(G_Baro_State, Conversion_Time_LUT, t_abs) then
                  read_adc (Baro, temperature_raw);
                  if temperature_raw /= 0 then            
                     dT   := calculateTemperatureDifference (temperature_raw, G_t_ref);
                     TEMP := Sat_Add_TempType (2000.0, Sat_Cast_TEMPType (dt * G_tempsens));                     
                     OFF  := Sat_Add_OFFType (G_off_t1, Sat_Cast_OffType (G_tco * dT));
                     SENS := Sat_Add_SensType (G_sens_t1, Sat_Cast_SensType (G_tcs * dT));
                     compensateTemperature;
                     temperature := convertToKelvin (TEMP);
                     start_conversion (D1, OSR_4096);
                     G_Baro_State.FSM_State := PRESSURE_CONVERSION;
                  else -- Read error, restart
                     start_conversion (D2, OSR_4096);
                     G_Baro_State.FSM_State := TEMPERATURE_CONVERSION;
                  end if;
               end if;
            end;

         when PRESSURE_CONVERSION =>
            declare
               t_abs : Ada.Real_Time.Time := Clock; -- see SPARK RM 7.1.3-12 (Clock cannot be a direct parameter)
            begin
               if conversion_Finished(G_Baro_State, Conversion_Time_LUT, t_abs) then
                  read_adc (Baro, pressure_raw);
                  if pressure_raw /= 0 then
                     pressure := calculatePressure (pressure_raw, SENS, OFF);
                     start_conversion (D2, OSR_4096);
                     G_Baro_State.FSM_State := TEMPERATURE_CONVERSION;
                  else
                     start_conversion (D1, OSR_4096);
                     G_Baro_State.FSM_State := PRESSURE_CONVERSION;
                  end if;
               end if;
            end;

      end case;

   end update_val;
   
end MS5611.Driver;
