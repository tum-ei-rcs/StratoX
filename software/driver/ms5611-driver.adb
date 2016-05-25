with Units;
use type Units.Unit_Type;
with HIL.SPI;   -- Hardware Interface to SPI
with MS5611.Register; use MS5611.Register;
--with Logger;    -- Log errors and debug info

package body MS5611.Driver is
   --pragma Unssuppress( Overflow_Check );
   --pragma Unsuppress( Range_Check );

   type Data_Array is array (Natural range <>) of HIL.Byte with
        Component_Size => 8;

      -- define baro states
   type Baro_FSM_Type is
     (NOT_INITIALIZED, READY, TEMPERATURE_CONVERSION, PRESSURE_CONVERSION);

   type Conversion_Info_Type is record
      OSR   : OSR_Type;
      Start : Time_Type;
   end record;

   type Baro_State_Type is record
      FSM_State      : Baro_FSM_Type;
      Conv_Info_Temp : Conversion_Info_Type;
      Conv_Info_Pres : Conversion_Info_Type;
   end record;

   type Conversion_Time_LUT_Type is array (OSR_Type) of Time_Type;

   type Coefficient_ID_Type is (SENS_T1, OFF_T1, TCS, TCO, T_REF, TEMPSENS);
   type Coefficient_Data_Type is mod 2**16 with
        Size => 16;

   type Conversion_ID_Type is (D1, D2);
   type Conversion_Data_Type is mod 2**24;

   subtype DT_Type is Float range -16776960.9 .. 16777216.9;
   subtype Sense_Type is Float range -4294836225.9 .. 6442352640.9;
   subtype OFF_Type is Float range -8589672450.9 .. 12884705280.9;

   subtype TEMP_Type is Float range -4000.9 .. 8500.9;

   -- Forward Declarations
   procedure startConversion (ID : Conversion_ID_Type; OSR : OSR_Type);
   function calculateTemperatureDifference
     (Temp_Raw : Conversion_Data_Type;
      T_Ref    : Float) return DT_Type;
   function calculateTEMP (dT : DT_Type; tempsens : Float) return TEMP_Type;
   procedure compensateTemperature;

   function convertToKelvin (Temp : in TEMP_Type) return Temperature_Type;

   function calculatePressure
     (Pressure_Raw : Conversion_Data_Type;
      SENS         : Sense_Type;
      OFF          : OFF_Type) return Pressure_Type;

   -- maximum conversion times (taken from the datasheet)
   Conversion_Time_LUT : constant Conversion_Time_LUT_Type :=
     (OSR_256  => Time_Type (0.60 / 1000.0),
      OSR_512  => Time_Type (1.17 / 1000.0),
      OSR_1024 => Time_Type (2.28 / 1000.0),
      OSR_2048 => Time_Type (4.54 / 1000.0),
      OSR_4096 => Time_Type (9.04 / 1000.0));

   -- conversion variables
   G_Baro_State : Baro_State_Type :=
     (FSM_State      => NOT_INITIALIZED,
      Conv_Info_Temp => (OSR_256, Time_Type (0.0)),
      Conv_Info_Pres => (OSR_256, Time_Type (0.0)));

   -- calibration variables (read values)
   G_sens_t1 : Float := 0.0;  -- Pressure sensitivity (54487)
   G_off_t1  : Float := 0.0;  -- Pressure offset (51552)
   G_tcs     : Float :=
     0.0;  -- Temperature coefficient of pressure sensitivity (33258)
   G_tco : Float := 0.0;  -- Temperature coefficient of pressure offset (27255)
   G_t_ref    : Float := 0.0;  -- barometer reference temperature (29426)
   G_tempsens : Float :=
     0.0;  -- Temperature coefficient of the temperature (27777)

   -- ADC values
   temperature_raw : Conversion_Data_Type :=
     0;  -- raw temperture read from baro
   pressure_raw : Conversion_Data_Type := 0;  -- raw pressure read from baro

   -- Compensation values
   dT : DT_Type := 0.0; -- difference between actual and reference temperature
   SENS : Sense_Type := 0.0; -- pressure sensitivity at the actual temperature
   OFF  : OFF_Type   := 0.0; -- pressure offset at actual temperature

   TEMP : TEMP_Type := 0.0;

   -- final measurement values
   pressure : Pressure_Type := 1000.0 * Units.Pascal;  -- invalid initial value
   temperature : Temperature_Type := 233.15 * Units.Kelvin;

   G_CELSIUS_0 : constant := 273.15;

   -- Glue Code
   -- the following procedures access the Hardware Interface Layer (HIL)

   procedure selectDevice (Device : Device_Type) is
   begin
      HIL.SPI.select_Chip (HIL.SPI.Barometer);
   end selectDevice;

   procedure deselectDevice (Device : Device_Type) is
   begin
      HIL.SPI.deselect_Chip (HIL.SPI.Barometer);
   end deselectDevice;

   procedure writeToDevice (Device : Device_Type; data : in Data_Array) is
   begin
      selectDevice (Device);
      HIL.SPI.write (HIL.SPI.Barometer, HIL.SPI.Data_Type (data));
      deselectDevice (Device);
   end writeToDevice;

   procedure transferWithDevice
     (Device  :        Device_Type;
      data_tx : in     Data_Array;
      data_rx :    out Data_Array)
   is
   begin
      selectDevice (Device);
      HIL.SPI.transfer
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

   -- \brief reads a PROM coefficient value
   procedure read_coefficient
     (Device     :     Device_Type;
      coeff_id   :     Coefficient_ID_Type;
      coeff_data : out Coefficient_Data_Type)
   is
      Data_TX : Data_Array (1 .. 3) := (others => 0);
      Data_RX : Data_Array (1 .. 3) := (others => 0);
   begin
      case coeff_id is
         when SENS_T1 =>
            Data_TX (1) := HIL.Byte (CMD_READ_C1);
         when OFF_T1 =>
            Data_TX (1) := HIL.Byte (CMD_READ_C2);
         when TCS =>
            Data_TX (1) := HIL.Byte (CMD_READ_C3);
         when TCO =>
            Data_TX (1) := HIL.Byte (CMD_READ_C4);
         when T_REF =>
            Data_TX (1) := HIL.Byte (CMD_READ_C5);
         when TEMPSENS =>
            Data_TX (1) := HIL.Byte (CMD_READ_C6);
      end case;

      transferWithDevice (Device, Data_TX, Data_RX);
      coeff_data :=
        Coefficient_Data_Type (Data_RX (3)) +
        Coefficient_Data_Type (Data_RX (2)) * (2**8);
      -- coeff_data := Convert( data(1 .. 2) );
   end read_coefficient;

   -- \brief reads the 24 bit ADC value from the barometer
   procedure read_adc
     (Device    :     Device_Type;
      adc_value : out Conversion_Data_Type) with
      Pre => adc_value'Size = 24 is
      Data_TX : constant Data_Array (1 .. 4) :=
        (1 => HIL.Byte (CMD_ADC_READ), others => 0);
      Data_RX : Data_Array (1 .. 4) := (others => 0);
   begin
      transferWithDevice (Device, Data_TX, Data_RX);
      adc_value :=
        Conversion_Data_Type (Data_RX (4)) +
        Conversion_Data_Type (Data_RX (3)) * (2**8) +
        Conversion_Data_Type (Data_RX (2)) * (2**16);
   end read_adc;

   procedure reset is
   begin
      writeToDevice (Baro, (1 => HIL.Byte (CMD_RESET)));
   end reset;

   -- \brief This function sequentially initializes the barometer.
   -- Therefore, the barometer is reset, the PROM-Coefficients are read and the starting-height (altitude_offset) is calculated.
   procedure init is
      c1 : Coefficient_Data_Type := 0;
      c2 : Coefficient_Data_Type := 0;
      c3 : Coefficient_Data_Type := 0;
      c4 : Coefficient_Data_Type := 0;
      c5 : Coefficient_Data_Type := 0;
      c6 : Coefficient_Data_Type := 0;
   begin
      read_coefficient (Baro, SENS_T1, c1);
      G_sens_t1 := Float (c1) * Float (2**15);

      read_coefficient (Baro, OFF_T1, c2);
      G_off_t1 := Float (c2) * Float (2**16);

      read_coefficient (Baro, TCS, c3);
      G_tcs := Float (c3) / Float (2**8);

      read_coefficient (Baro, TCO, c4);
      G_tco := Float (c4) / Float (2**7);

      read_coefficient (Baro, T_REF, c5);
      G_t_ref := Float (c5) * Float (2**8);

      read_coefficient (Baro, TEMPSENS, c6);
      G_tempsens := Float (c6) / Float (2**23);

      G_Baro_State.FSM_State := READY;

   end init;

   procedure update_val is
   begin
      -- Borometer takes 10ms (8.2ms) for one conversion, barometer_update_val gets called every main_loop (5ms)
      -- read conversion value every second to make sure barometer timing constraint is not violated
      case G_Baro_State.FSM_State is

         when NOT_INITIALIZED =>
            null;
         when READY =>
            startConversion (D2, OSR_4096);
            G_Baro_State.FSM_State := TEMPERATURE_CONVERSION;

         when TEMPERATURE_CONVERSION =>
            -- ToDo check time
            null;
            read_adc (Baro, temperature_raw);
            dT   := calculateTemperatureDifference (temperature_raw, G_t_ref);
            TEMP := 2000.0 + TEMP_Type (dT * G_tempsens);
            OFF  := G_off_t1 + G_tco * dT;
            SENS := G_sens_t1 + G_tcs * dT;
            compensateTemperature;
            temperature := convertToKelvin (TEMP);
            startConversion (D1, OSR_4096);
            G_Baro_State.FSM_State := PRESSURE_CONVERSION;

         when PRESSURE_CONVERSION =>
            -- ToDo check time
            null;
            read_adc (Baro, pressure_raw);
            pressure := calculatePressure (pressure_raw, SENS, OFF);
            G_Baro_State.FSM_State := READY;

      end case;

   end update_val;

   procedure self_check (Status : out Error_Type) is
      c3 : Coefficient_Data_Type := 0;
   begin
      -- check if initialized
      if G_Baro_State.FSM_State /= READY then
         Status := FAILURE;
      end if;

      -- read coefficient again and check equality
      read_coefficient (Baro, SENS_T1, c3);
      if (Float (c3) /= G_tcs) then
         Status := FAILURE;
      else
         -- read D2
         startConversion (D2, OSR_256);

         -- todo check
         Status := SUCCESS;
      end if;
   end self_check;

   procedure startConversion (ID : Conversion_ID_Type; OSR : OSR_Type) is
      data : Data_Array (1 .. 1) := (others => 0);
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
      end case;
      writeToDevice (Baro, data);

   end startConversion;

   function calculateTemperatureDifference
     (Temp_Raw : Conversion_Data_Type;
      T_Ref    : Float) return DT_Type
   is
   begin
      return DT_Type (Float (Temp_Raw) - T_Ref);
   end calculateTemperatureDifference;

   function calculateTEMP (dT : DT_Type; tempsens : Float) return TEMP_Type is
   begin
      return 2000.0 + TEMP_Type (dT * tempsens);
   end calculateTEMP;

   function convertToKelvin (Temp : in TEMP_Type) return Temperature_Type is
   begin
      return Temperature_Type (G_CELSIUS_0 + Temp / 100.0);
   end convertToKelvin;

   -- compensates values according to datasheet
   procedure compensateTemperature is
      T2    : TEMP_Type  := 0.0;
      OFF2  : OFF_Type   := 0.0;
      SENS2 : Sense_Type := 0.0;
   begin
      if TEMP < TEMP_Type (2000.0) then
         T2    := TEMP_Type (dT**2 / Float (2**31));
         OFF2  := OFF_Type (5.0 * (TEMP - TEMP_Type (2000.0))**2 / 2.0);
         SENS2 := Sense_Type (OFF2 / 2.0);

         if TEMP < TEMP_Type (-1500.0) then
            OFF2  := OFF2 + OFF_Type (7.0 * (TEMP - TEMP_Type (1500.0))**2);
            SENS2 :=
              SENS2 + Sense_Type (11.0 * (TEMP - TEMP_Type (1500.0))**2 / 2.0);
         end if;
      end if;
      TEMP := TEMP - T2;    -- this compensates the final temperature value
      OFF  := OFF - OFF2;
      SENS := SENS - SENS2;
   end compensateTemperature;

   function calculatePressure
     (Pressure_Raw : Conversion_Data_Type;
      SENS         : Sense_Type;
      OFF          : OFF_Type) return Pressure_Type
   is
   begin
      return Pressure_Type
          ((Float (Pressure_Raw) * SENS / Float (2**21) - OFF) /
           Float (2**15));
   end calculatePressure;

   function get_temperature return Temperature_Type is
   begin
      return temperature;
   end get_temperature;

   function get_pressure return Pressure_Type is
   begin
      return pressure;
   end get_pressure;

end MS5611.Driver;
