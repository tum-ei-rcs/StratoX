--  LED-Library by Emanuel Regnath (emanuel.regnath@tum.de)    Date:2_015-05-20
--
--  Description:
--  Portable LED Library that features switching, blinking and morse (non-blocking)
--
--  Setup:
--  To port the lib to your system, simply overwrite the 2 functions LED_HAL_init
--  and LED_HAL_set in the .c file and adjust the HAL part in the .h file
--
with HIL.GPIO; use HIL.GPIO;

package body LED_Manager is

   type LED_Mode_Type is (FIXED, BLINK);
   LED_mode : LED_Mode_Type := FIXED;
   LED_state : LED_State_Type := OFF;
   time_counter : Time_Type := 0;
   current_color : Color_Type := (1 => HIL.Devices.BLU_LED);

   type Pulse_Type is
       record
          time_mark_on  : Time_Type;
          time_mark_off : Time_Type;
       end record;
   current_pulse : Pulse_Type := (others => 0);

   Blink_Speed : constant LED_Blink_Speed_Type := (FLASH => BLINK_TIME / 2,
                                                   FAST => BLINK_TIME,
                                                   SLOW => BLINK_TIME * 3
                                                  );

   procedure LED_set (state : LED_State_Type) is
   begin
      LED_state := state;
      case state is
      when ON =>
         for c in current_color'Range  loop
            write (GPIO_Point_Type (current_color (c)), LOW); -- FIXME: pixracer drives LEDS with low
         end loop;
      when OFF =>
         HIL.GPIO.All_LEDs_Off;
      end case;
   end LED_set;

   --  switch functions
   procedure LED_switchOn is
   begin
      LED_mode := FIXED;
      LED_set (ON);
   end LED_switchOn;

   procedure LED_switchOff is
   begin
      LED_mode := FIXED;
      LED_set (OFF);
   end LED_switchOff;


   procedure Set_Color (col : Color_Type) is
   begin
      current_color := col;
   end Set_Color;

   --  blink functions
   procedure LED_blink (speed : LED_Blink_Type) is
      pulse_time : constant Time_Type := Blink_Speed (speed);
   begin
      LED_blinkPulse (pulse_time, pulse_time);
   end LED_blink;

   procedure LED_blinkPulse (on_time : Time_Type; off_time : Time_Type) is
   begin
      LED_mode := BLINK;
      current_pulse.time_mark_on := on_time;
      current_pulse.time_mark_off := current_pulse.time_mark_on + off_time;
   end LED_blinkPulse;

   --  sync functions
   procedure LED_tick (elapsed_time : Time_Type) is
   begin
      time_counter := time_counter + elapsed_time;
   end LED_tick;

   procedure LED_sync is
   begin
      if LED_mode /= FIXED then
         if LED_state = OFF  then
            if time_counter >= current_pulse.time_mark_off then
               time_counter := 0;
               if current_pulse.time_mark_on > 0 then  LED_set (ON); end if;
            elsif time_counter < current_pulse.time_mark_on then
               LED_set (ON);
            end if;
         elsif LED_state = ON  then
            if time_counter >= current_pulse.time_mark_on then
               LED_set (OFF);
            end if;
         end if;
      end if;
   end LED_sync;

end LED_Manager;
