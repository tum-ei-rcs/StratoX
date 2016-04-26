package HPL is
   pragma Preelaborate;


   type Analog_List is record
   		ADC_Count : Natural := 0;
   		DAC_Count : Natural := 0;
   	end record;


   type Bus_List is record
   		I2C_Count : Natural := 0;
   		SPI_Count : Natural := 0;
   		UART_Count : Natural := 0;
   		CAN_Count : Natural := 0;
   	end record;


   type Hardware_List_Type is record
   		GPIO_Count : Natural := 0;
   		Analog     : Analog_List;
   		Buses      : Bus_List;
   		Timer_Count : Natural := 0;
   		Power      : Boolean := True;
   		NVIC       : Boolean := True;
   	end 




   type Address_Type is abstract;
   type Register_Type is interface;

   -- do we need these functions? address access is not safe, better the register structure defines 'Address and the variable can accessed directly
   procedure write( hwreg : Register_Type, data : Register_Type) is abstract;
   function read( addr : Address_Type) return Register_Type is abstract;



end HPL;