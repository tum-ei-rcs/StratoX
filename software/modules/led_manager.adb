-- LED-Library by Emanuel Regnath (emanuel.regnath@tum.de)    Date:2_015-05-20
--
-- Description:
-- Portable LED Library that features switching, blinking and morse (non-blocking)
--
-- Setup:
-- To port the lib to your system, simply overwrite the 2 functions LED_HAL_init
-- and LED_HAL_set in the .c file and adjust the HAL part in the .h file
--
-- Usage:
-- 1. call LED_init which will configure the LED port and pin
-- 2. call LED_switch or LED_blink or LED_morse to select the operation mode
-- 3. frequently call LED_tick and LED_sync to manage LED timings.
--


-- ToDo: Support MORSE function (proper translation of C shifts)

with LED;

package body LED_Manager is

   type Bits_8 is mod 2**8;

   LED_id : LED_Id_Type;

   -- HAL: adjust these functions to your system
   -- ----------------------------------------------------------------------------
   procedure LED_HAL_init(LED_id : LED_Id_Type) is
   begin	
      LED.init;
   end LED_HAL_init;

   procedure LED_HAL_set(state : LED_State_Type) is
   begin
      case state is 
      when ON => LED.on;
      when OFF => LED.off;
      end case;
   end LED_HAL_set;
   -- ----------------------------------------------------------------------------


   type LED_Mode_Type is (FIXED, BLINK, MORSE);
   LED_mode : LED_Mode_Type := FIXED;


   LED_state : LED_State_Type := OFF;

   time_counter : Time_Type := 0;


   type Pulse_Type is
      record
         time_mark_on  : Time_Type;
         time_mark_off : Time_Type;
      end record;
   current_pulse : Pulse_Type := (others => 0);


   -- official morse timings
   MORSE_DIT_TIME : constant Time_Type := BLINK_TIME;
   MORSE_DAH_TIME : constant Time_Type := BLINK_TIME * 3;
   MORSE_PAUSE_TIME : constant Time_Type := BLINK_TIME * 7;

   Blink_Speed : constant LED_Blink_Speed_Type := (FLASH => BLINK_TIME/2,
                                                   FAST => BLINK_TIME,
                                                   SLOW => BLINK_TIME*3
                                                  );
   
   -- official morse codes:
   type morse_alphabet_Type is array (1 .. 26) of Bits_8;
   morse_alphabet : morse_alphabet_Type := ( -- first 1 bit defines length
                                             2#101#,    -- a: .-
                                             2#11000#,  -- b: -...
                                             2#11010#,  -- c: -.-.
                                             2#1100#,   -- d: -..
                                             2#10#,     -- e: .
                                             2#10010#,  -- f: ..-.
                                             2#1110#,   -- g: --.
                                             2#10000#,  -- h: ....
                                             2#100#,    -- i: ..
                                             2#10111#,  -- j: .---
                                             2#1101#,   -- k: -.-
                                             2#10100#,  -- l: .-..
                                             2#111#,    -- m: --
                                             2#110#,    -- n: -.
                                             2#1111#,   -- o: ---
                                             2#10110#,  -- p: .--.
                                             2#11101#,  -- q: --.-
                                             2#1010#,   -- r: .-.
                                             2#1000#,   -- s: ...
                                             2#11#,     -- t: -
                                             2#1001#,   -- u: ..-
                                             2#10001#,  -- v: ...-
                                             2#1011#,   -- w: .--
                                             2#11001#,  -- x: -..-
                                             2#11011#,  -- y: -.--
                                             2#11100#   -- z: --..
                                            );

   type morse_numbers_Type is array (1 .. 10) of Bits_8;
   morse_numbers : morse_numbers_Type := (
                                          2#111111#, -- 0: -----
                                          2#101111#, -- 1: .----
                                          2#100111#, -- 2: ..---
                                          2#100011#, -- 3: ...--
                                          2#100001#, -- 4: ....-
                                          2#100000#, -- 5: .....
                                          2#110000#, -- 6: -....
                                          2#111000#, -- 7: --...
                                          2#111100#, -- 8: ---..
                                          2#111110#  -- 9: ----.
                                         );

   pattern     : Character := ' ';
   pattern_length : Natural := 0;

   message     : String := "";
   message_length : Natural := 0;
   current_character_pos : Natural := 0;



   procedure LED_init(id : LED_Id_Type) is
   begin
      LED_id := id;
      LED_HAL_init(id);
   end LED_init;

   procedure LED_set(state : LED_State_Type) is
   begin
      LED_state := state;
      LED_HAL_set(LED_state);
   end LED_set;


   -- switch functions
   procedure LED_switchOn is
   begin
      LED_mode := FIXED;
      LED_set(ON);
   end LED_switchOn;
   
   procedure LED_switchOff is
   begin
      LED_mode := FIXED;
      LED_set(OFF);
   end LED_switchOff;

   

   -- blink functions
   procedure LED_blink(speed : LED_Blink_Type) is
      pulse_time : Time_Type := Blink_Speed(speed);
   begin
      LED_blinkPulse(pulse_time, pulse_time);
   end LED_blink;

   procedure LED_blinkPulse(on_time : Time_Type; off_time : Time_Type) is
   begin
      LED_mode := BLINK;
      current_pulse.time_mark_on := on_time;
      current_pulse.time_mark_off := current_pulse.time_mark_on + off_time;
   end LED_blinkPulse;


   -- morse functions
   --  procedure LED_loadNextCharacter is
   --  	current_character : Character := message(current_character_pos);
   --  begin
   --  	if current_character_pos >= message_length then 
   --  		current_character_pos := 0;
   --  	end if;
   --  
   --  	pattern_length := 1;
   --  
   --  	if current_character >= 'a' and then current_character <= 'z'  then   -- a-z
   --  		pattern := morse_alphabet( current_character - 'a' );
   --  	elsif current_character >= 'A' and then current_character <= 'Z'  then  -- A-Z
   --  		pattern := morse_alphabet( current_character - 'A' );
   --  	elsif current_character >= '0' and then current_character <= '9' then   -- 0-9
   --  		pattern := morse_numbers( current_character - '0' );
   --  	elsif current_character <= 32 then   -- space or escape chars
   --  		pattern := 1;  -- pause
   --  	else
   --  		pattern := 010_1000; -- wait signal
   --  	end if;
   --  
   --  	while  pattern >> (pattern_length + 1)  loop
   --  		pattern_length := pattern_length + 1;
   --  	end loop;  
   --  	current_character_pos := current_character_pos + 1;
   --  end LED_loadNextCharacter;

   --  procedure LED_morseNextPulse is
   --  begin
   --  	if pattern_length = 0 then 
   --  		LED_loadNextCharacter;
   --  	end if;
   --  	pattern_length := pattern_length - 1;
   --  
   --  	if pattern = 1  then 
   --  		current_pulse.time_mark_on := 0;
   --  		current_pulse.time_mark_off := MORSE_DAH_TIME + MORSE_DIT_TIME;  -- + pause from last Character := 7 * DIT_TIME 
   --  	else
   --  		if pattern and (Shift_Left(1, pattern_length))  then 
   --  			current_pulse.time_mark_on := MORSE_DAH_TIME;
   --  		else
   --  			current_pulse.time_mark_on := MORSE_DIT_TIME;
   --  		end if;
   --  	
   --  		if pattern_length = 0 then 
   --  			if current_character_pos < message_length then 
   --  				current_pulse.time_mark_off := current_pulse.time_mark_on + MORSE_DAH_TIME;	
   --  			else
   --  				current_pulse.time_mark_off := current_pulse.time_mark_on + MORSE_PAUSE_TIME;
   --  			end if;
   --  		else
   --  			current_pulse.time_mark_off := current_pulse.time_mark_on + MORSE_DIT_TIME;
   --  		end if;
   --  	end if;
   --  end LED_morseNextPulse;
   --  
   --  procedure LED_morse(Character* msg_string) is
   --  begin
   --  	LED_mode := MORSE;
   --  	message_length := 0;
   --  	message := msg_string;
   --  	while message(message_length) /= 0 loop
   --  	  message_length := message_length + 1;
   --  	end loop;
   --  	LED_loadNextCharacter;
   --  end LED_morse;




   -- sync functions
   procedure LED_tick(elapsed_time : Time_Type) is
   begin
      time_counter := time_counter + elapsed_time;
   end LED_tick;

   procedure LED_sync is
   begin
      if LED_mode = FIXED then 
         return;	 -- no timing needed
      end if;
      if LED_state = OFF  then 
         if time_counter >= current_pulse.time_mark_off then 
            time_counter := 0;
            if LED_mode = MORSE then
               null; -- LED_morseNextPulse;
            end if;
            if current_pulse.time_mark_on > 0 then  LED_set(ON); end if;
         elsif time_counter < current_pulse.time_mark_on then 
            LED_set(ON);
         end if;
      elsif LED_state = ON  then 
         if time_counter >= current_pulse.time_mark_on then 
            LED_set(OFF);
         end if;
      end if;
   end LED_sync;

   

end LED_Manager;
