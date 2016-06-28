-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Driver for the GPS Module Ublox LEA-6H
--
-- ToDo:
-- [ ] Implementation


with Units.Navigation; use Units.Navigation;
with HIL.UART;
with STM32.USARTs;

package ublox8.Driver with
SPARK_Mode,
Abstract_State => State
is

   type Error_Type is (SUCCESS, FAILURE);

   subtype Time_Type is Units.Time_Type;


   procedure reset;

   procedure init;

   procedure update_val;
   -- read measurements values. Should be called periodically.

   function get_Position return GPS_Loacation_Type;

   -- function get_Direction return Direction_Type;

   procedure perform_Self_Check (Status : out Error_Type);




private
   subtype Data_Type is HIL.UART.Data_Type;

end ublox8.Driver;
