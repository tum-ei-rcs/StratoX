with System;

--  @summary Catches all exceptions, logs them to NVRAM and reboots.
package Crash with SPARK_Mode is

   -- default exception handler (all exceptions will be catched here)
   procedure Last_Chance_Handler(location : System.Address; line : Integer) with No_Return;
   pragma Export (C, Last_Chance_Handler, "__gnat_last_chance_handler");

end Crash;
