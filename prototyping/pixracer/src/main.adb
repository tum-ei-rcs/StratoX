--  Description:
--  Main System File
--  todo: better unit name

with Ada.Real_Time;                     use Ada.Real_Time;
with Config;                            use Config;
with CPU;
with HIL.UART;
with HIL.SPI;
with NVRAM;
with Logger;
with LED_Manager;

package body Main is

   procedure Initialize is
      result : Boolean := False;
   begin
      CPU.initialize;
      delay until Clock + Milliseconds (50);
   end Initialize;

   procedure Run_Loop is
      data    : HIL.SPI.Data_Type (1 .. 3)  := (others => 0);
      data_rx : HIL.UART.Data_Type (1 .. 1) := (others => 0);
      msg     : constant String                      := "Main";

      loop_time_start   : Time      := Clock;
      loop_duration_max : Time_Span := Milliseconds (0);
   begin
      LED_Manager.LED_blink (LED_Manager.SLOW);

      Logger.log (Logger.INFO, msg);


      loop
         loop_time_start := Clock;

         --  LED heartbeat
         LED_Manager.LED_tick (MAIN_TICK_RATE_MS);
         LED_Manager.LED_sync;

--           --  UART Test
--           --  HIL.UART.write(HIL.UART.Console, (70, 65) );
--           HIL.UART.read (HIL.UART.Console, data_rx);
--
--           case (Character'Val (data_rx (1))) is
--
--              when 'l' =>
--                 LED_Manager.LED_blink (LED_Manager.FAST);
--              when 'd' =>
--                 null;
--                 --  PX4IO.Driver.disarm;
--              when 'p' =>
--                 Logger.log
--                   (Logger.INFO,
--                    Integer'Image (loop_duration_max / Time_Span_Unit));
--              when others =>
--                 null;
--           end case;


         --  SPI Test
         --  HIL.SPI.select_Chip(HIL.SPI.Extern);
         --  HIL.SPI.transfer(HIL.SPI.Extern, (166, 0, 0), data );
         --  HIL.SPI.deselect_Chip(HIL.SPI.Extern);

         --  profile
         if loop_duration_max < (Clock - loop_time_start) then
            loop_duration_max := Clock - loop_time_start;
         end if;

         --  wait remaining loop time
         delay until loop_time_start + Milliseconds (MAIN_TICK_RATE_MS);
      end loop;
   end Run_Loop;

end Main;
