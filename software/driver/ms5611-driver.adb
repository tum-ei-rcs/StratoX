

with units;  use type units.Unit_Type;
with HIL.I2C;	-- Hardware Interface to I2C
with MS5611.Register; use MS5611.Register;
--with Logger;    -- Log errors and debug info

package body MS5611.Driver is
	--pragma Unssuppress( Overflow_Check );
	--pragma Unsuppress( Range_Check );

   type Data_Array is array (Natural range <>) of HIL.Byte with Component_Size => 8;

   
	-- define baro states 
	type Baro_FSM_Type is (
			NOT_INITIALIZED,
			READY,
			TEMPERATURE_CONVERSION,
			PRESSURE_CONVERSION	
		);


	type Conversion_Info_Type is record
		OSR      : OSR_Type;
		Start    : Time_Type;
	end record;


	type Baro_State_Type is record
		FSM_State : Baro_FSM_Type;
		Conv_Info_Temp : Conversion_Info_Type;
		Conv_Info_Pres : Conversion_Info_Type;
	end record;


	type Conversion_Time_LUT_Type is array (OSR_Type) of Time_Type;

	type Coefficient_ID_Type is (
			SENS_T1, 
			OFF_T1, 
			TCS, 
			TCO, 
			T_REF, 
			TEMPSENS
		);
	type Coefficient_Data_Type is mod 2**16 with Size => 16;

	type Conversion_ID_Type is (
			D1,
			D2
		);
	type Conversion_Data_Type is mod 2**24; 

	subtype DT_Type    is Integer           range   -16776960 ..    16777216;
	subtype Sense_Type is Long_Long_Integer range -4294836225 ..  6442352640;
	subtype OFF_Type   is Long_Long_Integer range -8589672450 .. 12884705280;


  -- Forward Declarations
   procedure startConversion(ID : Conversion_ID_Type; OSR : OSR_Type);
   function calculateTemperatureDifference(
					   Temp_Raw : Conversion_Data_Type; 
					   C5       : Coefficient_Data_Type		
					  )
					  return DT_Type;
   function calculateTemperature(
				 dT : DT_Type;
				 C6 : Coefficient_Data_Type)
				 return Temperature_Type;
   procedure compensateTemperature;
   function calculatePressure(
		Pressure_Raw : Conversion_Data_Type;
		SENS         : Sense_Type;
		OFF          : OFF_Type
		) 
	return Pressure_Type;

	-- maximum conversion times (taken from the datasheet)
	Conversion_Time_LUT : Conversion_Time_LUT_Type := (
		OSR_256  => Time_Type( 0.60 /1000.0 ),
		OSR_512  => Time_Type( 1.17 /1000.0 ),
		OSR_1024 => Time_Type( 2.28 /1000.0 ),
		OSR_2048 => Time_Type( 4.54 /1000.0 ),
		OSR_4096 => Time_Type( 9.04 /1000.0 )
	);

	-- conversion variables
	G_Baro_State : Baro_State_Type := (
		FSM_State => NOT_INITIALIZED,
		Conv_Info_Temp => (OSR_256, Time_Type(0.0) ),
		Conv_Info_Pres => (OSR_256, Time_Type(0.0) )
		);


	-- calibration variables (read values)
	G_sens_t1  : Float := 0.0;  -- Pressure sensitivity (54487)
	G_off_t1   : Float := 0.0;  -- Pressure offset (51552)
	G_tcs      : Float := 0.0;  -- Temperature coefficient of pressure sensitivity (33258)
	G_tco      : Float := 0.0;  -- Temperature coefficient of pressure offset (27255)
	G_t_ref    : Float := 0.0;  -- barometer reference temperature (29426)
	G_tempsens : Float := 0.0;  -- Temperature coefficient of the temperature (27777)

	C1 : Coefficient_Data_Type := 0;  -- Pressure sensitivity (54487)
	C2 : Coefficient_Data_Type := 0;  -- Pressure offset (51552)
	C3 : Coefficient_Data_Type := 0;  -- Temperature coefficient of pressure sensitivity (33258)
	C4 : Coefficient_Data_Type := 0;  -- Temperature coefficient of pressure offset (27255)
	C5 : Coefficient_Data_Type := 0;  -- barometer reference temperature (29426)
	C6 : Coefficient_Data_Type := 0;  -- Temperature coefficient of the temperature (27777)


	-- ADC values
	temperature_raw : Conversion_Data_Type := 0;  -- raw temperture read from baro 
	pressure_raw    : Conversion_Data_Type := 0;  -- raw pressure read from baro 

	-- Compensation values
	dT   : DT_Type    := 0; -- difference between actual and reference temperature
	SENS : Sense_Type := 0; -- pressure sensitivity at the actual temperature	
	OFF  : OFF_Type   := 0; -- pressure offset at actual temperature 

	-- final measurement values 
	pressure    : Pressure_Type    := 1000.0;  -- invalid initial value
	TEMP : Temperature_Type :=  233.15;

   G_CELSIUS_0 : constant := 273.15;
   
   
	-- Glue Code
	-- the following procedures access the Hardware Interface Layer (HIL)
   procedure writeToDevice(Device : Device_Type; data : in Data_Array) is
	begin
		HIL.I2C.write(HIL.I2C.BARO, HIL.I2C.Data_Type( data ) );
	end writeToDevice;

	procedure readFromDevice(Device : Device_Type; data : out Data_Array) is
	begin
		HIL.I2C.read(HIL.I2C.BARO, HIL.I2C.Data_Type( data ) );
	end readFromDevice;

	procedure transferWithDevice(data_tx : in Data_Array; data_rx : out Data_Array) is
	begin
		HIL.I2C.transfer(HIL.I2C.BARO, HIL.I2C.Data_Type( data_tx ), HIL.I2C.Data_Type( data_rx ) );
	end transferWithDevice;	




	procedure sendCommand(Device : Device_Type; command : in Command_Type) is
		Command_Data : Data_Array (1 .. 1) :=  (1 => HIL.Byte ( command ) );
	begin
		writeToDevice(Device, Command_Data);
	end sendCommand;





	-- \brief reads a PROM coefficient value
	procedure read_coefficient (
			Device : Device_Type;
			coeff_id : Coefficient_ID_Type;
			coeff_data : out Coefficient_Data_Type 
		) 
	is
		command : Command_Type := 0;
		data    : Data_Array(1 .. 2) := (others => 0);
	begin
		case coeff_id is
			when SENS_T1 => command := CMD_READ_C1;
			when OFF_T1  => command := CMD_READ_C2;
			when TCS     => command := CMD_READ_C3;
			when TCO     => command := CMD_READ_C4;
			when T_REF   => command := CMD_READ_C5;
			when TEMPSENS => command := CMD_READ_C6;
		end case;
		sendCommand(Device, command);
		readFromDevice(Device, data);
		coeff_data := Coefficient_Data_Type( data(1) ) + Coefficient_Data_Type( data(2) )*(2*8);
	end read_coefficient;


	-- \brief reads the 24 bit ADC value from the barometer
	procedure read_adc (Device : Device_Type; adc_value : out Conversion_Data_Type)
	with pre => adc_value'Size = 24
   is
      data    : Data_Array(1 .. 3) := (others => 0);
	begin
		sendCommand (Device, CMD_ADC_READ);
                readFromDevice(Device, data);
      adc_value := Conversion_Data_Type ( data(1) ) + Conversion_Data_Type ( data(2) )*(2**8) + Conversion_Data_Type ( data(3) )*(2**16);
	end read_adc;



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
		sendCommand(Baro, CMD_RESET);
		read_coefficient(Baro, SENS_T1, c1);
		G_sens_t1 := Float ( c1 ) * Float( 2**15 );

		read_coefficient(Baro, OFF_T1, c2);
		G_off_t1 := Float ( c2 ) * Float( 2**15 );

		read_coefficient(Baro, TCS, c3);
		G_tcs := Float( c3 );

		read_coefficient(Baro, TCO, c4);
		G_tco := Float( c4 );

		read_coefficient(Baro, T_REF, c5);
		G_t_ref := Float( c5 ) * Float( 2**8 );

		read_coefficient(Baro, TEMPSENS, c6);
		G_tempsens := Float ( c6 ) / Float( 2**23 );	

	end init;


	-- updates
	procedure update_val is
	begin
		-- Borometer takes 10ms (8.2ms) for one conversion, barometer_update_val gets called every main_loop (5ms) 
		-- read conversion value every second to make sure barometer timing constraint is not violated
		case G_Baro_State.FSM_State is 
			
	 when NOT_INITIALIZED => null;
      when READY => 
				startConversion(D2, OSR_4096);

			when TEMPERATURE_CONVERSION =>
				-- ToDo check time
				null;
				read_adc(Baro, temperature_raw);
				dT := calculateTemperatureDifference(temperature_raw, c5);
				compensateTemperature;
				TEMP := calculateTemperature( dT, C6 );
				startConversion( D1, OSR_4096 );


			when PRESSURE_CONVERSION =>
				-- ToDo check time
				null;
				read_adc(Baro, pressure_raw);
				pressure := calculatePressure( pressure_raw, SENS, OFF ); 

		
		end case;

	end update_val;

	 
	 	-- \brief This function implements the self-check of the barometer.
	-- It checks the measured altitude for validity by comparing them to altitude_offset.
	-- Furthermore it can adapt the starting-height.
	procedure self_check( Status : out Error_Type ) is
		c3 : Coefficient_Data_Type := 0;
	begin		
		-- check if initialized
      if G_Baro_State.FSM_State /= READY then
	 Status := FAILURE;
      end if;
      
      
		-- read coefficient again and check equality
		read_coefficient ( Baro, SENS_T1, c3 );
		if ( Float ( c3 ) /= G_tcs ) then
			Status := FAILURE;
		else
			-- read D2 
			startConversion(D2, OSR_256);

			-- todo check
			Status := SUCCESS;
		end if;
	end self_check;



	procedure startConversion(ID : Conversion_ID_Type; OSR : OSR_Type) is
      Cmd : Command_Type := 0;
      data : Data_Array(1 .. 1) := (1 => 0);
	begin
		case (ID) is
			when D1 => Cmd := CMD_CONV_D1;
			when D2 => Cmd := CMD_CONV_D2;
		end case;

		case (OSR) is
			when OSR_256  => Cmd := Cmd + Command_Type(0);
			when OSR_512  => Cmd := Cmd + Command_Type(2);
			when OSR_1024 => Cmd := Cmd + Command_Type(4);
			when OSR_2048 => Cmd := Cmd + Command_Type(6);
			when OSR_4096 => Cmd := Cmd + Command_Type(8);
		end case;
      data(1) := HIL.Byte(Cmd); 
		writeToDevice(Baro, data);
	end startConversion;


	function calculateTemperatureDifference(
		Temp_Raw : Conversion_Data_Type; 
		C5       : Coefficient_Data_Type		
	)
	return DT_Type
   is 
      begin
		return DT_Type( Integer( Temp_Raw ) - Integer(C5 * 2**8) );
	end calculateTemperatureDifference;


	function calculateTemperature(
		dT : DT_Type;
		C6 : Coefficient_Data_Type)
	return Temperature_Type
	is
	begin
		return Temperature_Type( (2000 + Integer( dT ) * Integer ( C6 ) ) / 2**23);
	end calculateTemperature;



	-- compensates values according to datasheet
	procedure compensateTemperature is
		T2    : Temperature_Type := 273.15;
		OFF2  : OFF_Type := 0;
		SENS2 : Sense_Type := 0;
	begin
		if TEMP < Temperature_Type (20.0 + G_CELSIUS_0) then
			T2   := Temperature_Type ( Float( dT**2 ) / Float (2**31) );
			OFF2 := OFF_Type (5.0 * (TEMP - Temperature_Type( 20.0 + G_CELSIUS_0) )**2 / 2.0);
			SENS2 := Sense_Type( OFF2 / 2 );

			if TEMP < units.Temperature_Type (-15.0 ) + units.CELSIUS_0 then
				OFF2  := OFF2  +  OFF_Type ( 7.0 * (TEMP - Temperature_Type (15.0 + G_CELSIUS_0) )**2 );
				SENS2 := SENS2 + Sense_Type ( 11.0 * (TEMP - Temperature_Type (15.0 + G_CELSIUS_0) )**2 / 2.0 );
			end if;
		end if;
		TEMP := TEMP - T2;    -- this compensates the final temperature value
		OFF  := OFF  - OFF2;  
		SENS := SENS - SENS2;
	end compensateTemperature;		


	function calculatePressure(
		Pressure_Raw : Conversion_Data_Type;
		SENS         : Sense_Type;
		OFF          : OFF_Type
		) 
	return Pressure_Type
	is
	begin
		return Pressure_Type ( (Float ( Pressure_Raw ) * Float( SENS/2**21 ) - Float( OFF ) ) / Float( 2**15 ) );
	end calculatePressure;



	function get_temperature return Temperature_Type is
	begin
		return TEMP;
	end get_temperature;

	function get_pressure return Pressure_Type is
	begin
		return pressure;
	end get_pressure;

end MS5611.Driver;
