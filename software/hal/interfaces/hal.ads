package HAL is
   pragma Preelaborate;


   type GPIO_Port_Type is abstract;

   type ADC_Type is abstract;
   type DAC_Type is abstract;
   type TIM_Type is abstract;

   type I2C_Type is abstract;
   type UART_Type is abstract;
   type SPI_Type is abstract;
   type CAN_Type is abstract;


   --type GPIO_Point_Array is array (Positive range <>) of GPIO_Point
   generic
      GPIO_Ports : Natural := 0;
      ADCs    : Natural := 0; 
      I2Cs    : Natural := 0;
      UARTs   : Natural := 0;
      Timers  : Natural := 0;
   type HAL_Object is record
      GPIO_Port : array(1 .. PIO_Ports) of GPIO_Port_Type;
      ADC : array(1 .. ADCs) of ADC_Type;
      I2C : array(1 .. I2Cs) of I2C_Type;
      UART : array(1 .. UARTs) of UART_Type;
      TIM : array(1 .. Timers) of TIM_Type;
   end record;


   
   type HAL_Module_Type is interface;
   type HAL_Module_Configuration_Type is abstract;

   procedure configure(module : HAL_Module_Type; configuration : HAL_Module_Configuration_Type) is abstract;



   -- Hardware identifier
   type Hardware_Type is abstract;


   -- this object represents the whole Hardware
   type HAL_Object is limited interface;

   -- creates a HAL Object according to a hardware id
   function createHAL(id : Hardware_Type) return HAL_Object is abstract;

   -- function initHAL(hw : HAL_Object) is abstract;

end HAL;