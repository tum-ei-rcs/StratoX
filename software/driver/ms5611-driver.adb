

with HIL.I2C;	-- Hardware Interface to I2C
with Logger;    -- Log errors and debug info

package body MS5611.Driver is
	--pragma Unssuppress( Overflow_Check );
	--pragma Unsuppress( Range_Check );


	-- define baro states 
	type Baro_State_Type is (
			BARO_START_MEASUREMENT,
			BARO_WAIT,
			BARO_READ_TEMPERATURE,
			BARO_WAIT_FOR_PRESSURE,
			BARO_READ_PRESSURE,
			BARO_WAIT_FOR_TEMPERATURE
		);

	-- define shift conversions 
	SHIFT_7 : constant := Uint16(16#80#);
	SHIFT_8 : constant := Uint32(16#100#);
	--pragma Linker_Section (SHIFT_8, ".text");
	SHIFT_15 : constant := Uint32(16#8000#);
	SHIFT_16 : constant := Uint32(16#1_00_00#);
	SHIFT_21 : constant := Uint32(16#20_00_00#);
	SHIFT_23 : constant := Uint32(16#80_00_00#);
	SHIFT_31 : constant := Uint32(16#80_0_00_00#);

	-- define calculation constants 
	BARO_DEG_20 : constant := Integer_32(2_000);


	BARO_ALTI_DEVIATION_MAX : constant := Integer_32(50);

	baro_init_step : Baro_Init_Step_Type := INIT;
	
	-- conversion variables
	barometer_conversion_state : Baro_State_Type := BARO_START_MEASUREMENT; -- state variable of statemachine

	temperature_raw : Uint32 := 0;	-- raw temperture read from baro 
	pressure_raw : Uint32 := 0;		-- raw pressure read from baro 
	temperature_offset : Integer_64 := 0;	-- difference between actual and reference temperature 
	pressure_offset : Integer_64 := 0;	-- Offset at actual temperature 
	sensitivity : Integer_64 := 0; 		-- pressure sensitivity at the actual temperature 

	-- static 
	check_state : Uint8 := 0;

	-- calibration variables (read values)
	sens_t1 : Uint32;      -- Pressure sensitivity (54487)
	off_t1 : Unsigned_64;  -- Pressure offset (51552)
	tcs : Uint16;          -- Temperature coefficient of pressure sensitivity (33258)
	tco : Uint16;          -- Temperature coefficient of pressure offset (27255)
	t_ref : Integer_64;    -- barometer reference temperature (29426)
	tempsens : Integer_64; -- Temperature coefficient of the temperature (27777)

	-- measured values 
	pressure : Integer_32;
	temperature : Integer_64;


	-- Glue Code
	-- the following procedures access the Hardware Interface Layer (HIL)
	procedure writeToDevice(Device : Device_Type; data : in Data_Array) is
	begin
		HIL.I2C.write(Baro, data);
	end writeToDevice;

	procedure readFromDevice(Device : Device_Type; data : out Data_Array) is
	begin
		HIL.I2C.read(Baro, data);
	end readFromDevice;

	procedure transferWithDevice(data_tx : in Data_Array, data_rx : out Data_Array) is
	begin
		HIL.I2C.transfer(Baro, data);
	end writeToDevice;	




	procedure sendCommand(Device : Device_Type; command : in Byte) is
		Command_Data : Data_Array (1) := command;
	begin
		writeToDevice(Device, Command_Data);
	end sendCommand;


	type Coefficient_ID_Type is (SENS_T1, OFF_T1, TCS, TCO, T_REF, TEMPSENS);
	subtype Coefficient_Data_Type is new Data_Array(1 .. 2);


	-- \brief reads a PROM coefficient value
	procedure read_coefficient (
			Device : Device_Type;
			command : in Byte;
			coeff : in Coefficient_ID_Type;
			data : out Coefficient_Data_Type; 
		) 
	is
	begin
		sendCommand(Device, coeff);
		readFromDevice(Device, data);
	end read_coefficient;


	-- \brief reads the 24 bit ADC value from the barometer
	procedure read_adc (Device : Device_Type; adc_value : out Data_Array) 
	with pre => adc_value'Size = 24
	is
	begin
		sendCommand (Device, CMD_ADC_READ);
		readFromDevice(Device, adc_value);
	end read_adc;



	-- \brief This function sequentially initializes the barometer.
	-- Therefore, the barometer is reset, the PROM-Coefficients are read and the starting-height (altitude_offset) is calculated.
	function init return Init_Error_Code is	
		c1 : Coefficient_Data_Type := (others => 0);
		c2 : Coefficient_Data_Type := (others => 0);
		c3 : Coefficient_Data_Type := (others => 0);
		c4 : Coefficient_Data_Type := (others => 0);
		c5 : Coefficient_Data_Type := (others => 0);
		c6 : Coefficient_Data_Type := (others => 0);
	begin
		sendCommand(Baro, CMD_RESET);
		read_coefficient(Baro, CMD_PROM_RD, SENS_T1, c1);
		sens_t1 := c1 * SHIFT_15;

		read_coefficient(Baro, CMD_PROM_RD, OFF_T1, c2);
		off_t1 := Unsigned_64(Uint32(c2) * SHIFT_16);

		read_coefficient(Baro, CMD_PROM_RD, TCS, c3);
		tcs := c3;

		read_coefficient(Baro, CMD_PROM_RD, TCO, c4);
		tco := c4;

		read_coefficient(Baro, CMD_PROM_RD, T_REF, c5);
		t_ref := Integer_64(c5) * Integer_64(SHIFT_8);

		read_coefficient(Baro, CMD_PROM_RD, TEMPSENS, c6);
		tempsens := Integer_64(c6);	

		return SUCCESS;
	end init;



	function update_val return Sample_Status_Type is
		barometer_status : Sample_Status_Type;
		err : twi.Twi_Status_Type := twi.OK; -- TODO: evaluate that value...
	    pressure_offset_20 : Integer_64 := 0;	--*< Barometer-offset for temperature compensation below 20C
	    sensitivity_20 : Integer_64 := 0;		--*< Barometer-sensitivity for temperature compensation below 20C
	begin
		-- Borometer takes 10ms (8.2ms) for one conversion, barometer_update_val gets called every main_loop (5ms) 
		-- read conversion value every second to make sure barometer timing constraint is not violated
		case barometer_conversion_state is 
			when BARO_START_MEASUREMENT => 
				twi.send_cmd(BAROMETER_ADR, BAR_ADC_CONV+BAR_ADC_D2+BAR_ADC4_096, err);	--Start Temperature-conversion, OSR:4_096
				barometer_conversion_state := BARO_WAIT;
				barometer_status := BARO_NO_NEW_VALUE;

			when BARO_WAIT =>
				if barometer_status =  BARO_READ_PRESSURE_ERROR then 
					barometer_conversion_state := BARO_READ_PRESSURE;
				else
					barometer_conversion_state := BARO_READ_TEMPERATURE;
				end if;
				barometer_status := BARO_NO_NEW_VALUE;

			when BARO_READ_TEMPERATURE =>
				read_adc(temperature_raw, err);	--D2
				if temperature_raw = 0 then 
					-- read to early, restart converison 
					twi.send_cmd(BAROMETER_ADR, BAR_ADC_CONV+BAR_ADC_D2+BAR_ADC4_096, err);	--Start Temperature-conversion, OSR:4_096
					barometer_status := BARO_READ_TEMPERATURE_ERROR;
					barometer_conversion_state := BARO_WAIT;	-- wait without calculations, there are no new values
				else
					-- start pressure conversion 
					twi.send_cmd(BAROMETER_ADR, BAR_ADC_CONV+BAR_ADC_D1+BAR_ADC4_096, err);	--Start Pressure-conversion, OSR:4_096
					barometer_status := BARO_NEW_TEMPERATURE;
					barometer_conversion_state := BARO_WAIT_FOR_PRESSURE;
					-- calculate temperature related values 
					temperature_offset := Integer_64(temperature_raw) - t_ref;	--dT
					temperature := Integer_64(BARO_DEG_20 + (temperature_offset * tempsens) / SHIFT_23);	--TEMP
				end if;

			when BARO_WAIT_FOR_PRESSURE =>
				pressure_offset := Integer_64(off_t1) + ( Integer_64(tco) * temperature_offset ) / SHIFT_7;	--OFF

				sensitivity := Integer_64(sens_t1) + ( temperature_offset * Integer_64(tcs) ) / SHIFT_8;
				-- Recalculate compensation values if temperature is below 20 degree  
				if temperature < BARO_DEG_20 then 
					
				    pressure_offset_20 := Integer_64(5*(temperature-Integer_64(2_000))*(temperature-Integer_64(2_000))/2);
				    sensitivity_20 := pressure_offset_20/2;
				 --    if temperature < BARO_DEG_15 then  -- see datasheet
					-- 	pressure_offset_20 := pressure_offset_20 + 7 * (temperature + Integer_64(BARO_DEG_15))**2;
					-- 	sensitivity_20 := sensitivity_20 + 11 * (temperature + Integer_64(BARO_DEG_15))**2 / 2;
					-- end if;
					temperature := Integer_64(temperature - ((temperature_offset*temperature_offset)/SHIFT_31));
				    pressure_offset := pressure_offset - pressure_offset_20;
				    sensitivity := sensitivity - sensitivity_20;				
				end if;
				
				-- get new pressure value in next state 
				barometer_conversion_state := BARO_READ_PRESSURE;
				barometer_status := BARO_NEW_TEMPERATURE;

			when BARO_READ_PRESSURE =>
				-- read pressure from register 
				read_adc(pressure_raw, err);
				if pressure_raw = 0 then
					-- read to early, restart converison 
					twi.send_cmd(BAROMETER_ADR, BAR_ADC_CONV+BAR_ADC_D1+BAR_ADC4_096, err);	--Start Pressure-conversion, OSR:4_096
					barometer_status := BARO_READ_PRESSURE_ERROR;
					barometer_conversion_state := BARO_WAIT;	-- wait without calculations, there are no new values
				else
					-- start temperature conversion 
					twi.send_cmd(BAROMETER_ADR, BAR_ADC_CONV+BAR_ADC_D2+BAR_ADC4_096, err);	--Start Temperature-conversion, OSR:4_096
					barometer_status := BARO_NO_NEW_VALUE;
					barometer_conversion_state := BARO_WAIT_FOR_TEMPERATURE;
				end if;
			
			when BARO_WAIT_FOR_TEMPERATURE =>
				pressure := Integer_32( ( Integer_64(pressure_raw) * ( sensitivity / Integer_64(SHIFT_21) )  
						- pressure_offset ) / Integer_64(SHIFT_15) );
				--get new temperature value in next state 
				barometer_conversion_state := BARO_READ_TEMPERATURE;
				barometer_status := BARO_NEW_PRESSURE;
		
		end case;

		return barometer_status;	
	end update_val;

	 
	 	-- \brief This function implements the self-check of the barometer.
	-- It checks the measured altitude for validity by comparing them to altitude_offset.
	-- Furthermore it can adapt the starting-height.
	function self_check return Self_Check_Status is
		altitude : Integer_32 := barometer_calc.baro_calc_altitude (pressure);
		altitude_offset : Integer_32 := barometer_calc.baro_get_altitude_offset;
	begin		
		case check_state is 
		when 0 =>	--Wait for conversion
			if update_val = BARO_NEW_PRESSURE then 
				if altitude < altitude_offset + BARO_ALTI_DEVIATION_MAX and then 
						altitude > altitude_offset - BARO_ALTI_DEVIATION_MAX then 	
						--Deviation of altitude_raw and altitude_offset is < 0.5m
					check_state := check_state + 1;
				else
					barometer_calc.baro_set_altitude_offset ((altitude_offset+altitude)/2);
				end if;
			end if;
		when 1 =>
			check_state := 0;
			return CHECKING_DONE;
		when others =>
			null;
		end case;

		return CHECKING;
	end self_check;






	function get_temperature return CentiCelsius is
	begin
		return Integer_32(temperature);
	end get_temperature;

	function get_pressure return Integer_32 is
	begin
		return pressure;
	end get_pressure;

end MS5611.Driver;
