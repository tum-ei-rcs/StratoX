
-- LED-Library by Emanuel Regnath (emanuel.regnath@tum.de)    Date:2_015-05-20
--
-- Description:
-- Portable LED Library that features switching, blinking and morse (non-blocking)
--
-- Setup:
-- To port the lib to your system, simply overwrite the 2 functions LED_HAL_init
-- and LED_HAL_set in the .cpp file and adjust the HAL part in the .hpp file
--
-- Usage:
-- 1. call LED_init which will configure the LED port and pin
-- 2. call LED_switch or LED_blink or LED_morse to select the operation mode
-- 3. frequently call LED_tick and LED_sync to manage LED timings.
--




package led_manager is



-- HAL: adjust these types to your system
-- ----------------------------------------------------------------------------

type Time_Type is new Natural;          -- max. value: 7 * BLINK_TIME
BLINK_TIME : constant Time_Type := 250; -- arbitrary time basis (dot time in morse mode)
type Led_Id_Type is new Integer;        -- any led identifier e.g. struct with port and pin 

-- ----------------------------------------------------------------------------


type LED_State_Type is (ON, OFF);

   type LED_Blink_Type is (
			   FLASH, 
			   FAST, 
			   SLOW
			  );
type LED_Blink_Speed_Type is array (LED_Blink_Type) of Time_Type;
  


-- configures which LED to use 
procedure LED_init(id : Led_Id_Type);

-- increases the internal timing counter
-- elapsed_time should be a divider of BLINK_TIME. 
procedure LED_tick(elapsed_time : Time_Type);

-- perform LED switching in blink or morse mode 
procedure LED_sync;

-- switch LED on or off (will stop blink or morse mode)   
procedure LED_switchOn;
procedure LED_switchOff;

-- select blink mode 
procedure LED_blink(speed : LED_Blink_Type);
procedure LED_blinkPulse(on_time : Time_Type; off_time : Time_Type);

-- select morse mode 
-- procedure LED_morse(msg_string : String);   -- ensure 0-terminated string!


end led_manager;
