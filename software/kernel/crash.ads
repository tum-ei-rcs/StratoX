with System;

--  @summary Catches all exceptions, logs them to NVRAM and reboots.
package Crash with SPARK_Mode => Off is
   --  XXX! SPARK must be off here, otherwise this function is not being implemented.

   -- default exception handler (all exceptions will be catched here)
   procedure Last_Chance_Handler(location : System.Address; line : Integer) with No_Return;
   pragma Export (C, Last_Chance_Handler, "__gnat_last_chance_handler");

end Crash;
