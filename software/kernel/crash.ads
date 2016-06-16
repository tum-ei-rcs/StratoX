
with System;

package Crash is

   -- default exception handler (all exceptions will be catched here)
   procedure Last_Chance_Handler(location : System.Address; line : Integer);
   pragma Export (C, Last_Chance_Handler, "__gnat_last_chance_handler");


end Crash;
