--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Emanuel Regnath (emanuel.regnath@tum.de)
with Config.Software;
with HIL.UART;
with HIL.Devices;

--  @summary Command Line Interface for user interactions
package body Console with SPARK_Mode => On is

   procedure read_Command( cmd : out User_Command_Type ) is
      data_rx : HIL.UART.Data_Type (1 .. 1) := (others => 0);
      n_read : Natural;
   begin
      cmd := NONE;
      if Config.Software.DEBUG_MODE_IS_ACTIVE then
         HIL.UART.read (HIL.Devices.Console, data_rx, n_read);
         if n_read > 0 then

            case (Character'Val (data_rx (1))) is
            when 's' =>
               cmd := STATUS;

            when 't' =>
               cmd := TEST;

            when 'p' =>
               cmd := PROFILE;

            when 'r' =>
               cmd := RESTART;

            when 'a' =>
               cmd := ARM;

            when 'd' =>
               cmd := DISARM;

            when '2' =>
               cmd := INC_ELE;

            when '1' =>
               cmd := DEC_ELE;

            when others =>
               cmd := NONE;
            end case;
         end if;
      end if;
   end read_Command;


   procedure write_Line (message : String) is
      --LF : Character := Character'Val(10);
      CR : constant Character := Character'Val (13);  -- ASCII
   begin
      if message'Last < Natural'Last then
         HIL.UART.write (HIL.Devices.Console, HIL.UART.toData_Type (message & CR));
      else
         HIL.UART.write (HIL.Devices.Console, HIL.UART.toData_Type (message));
      end if;
   end write_Line;

end Console;
