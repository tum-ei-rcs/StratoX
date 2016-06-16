

with Logger;
with System;
with Boot;

with Unchecked_Conversion;

package body Crash is

   function To_Integer is new Unchecked_Conversion (System.Address, Integer);

   procedure Last_Chance_Handler(location : System.Address; line : Integer) is
   begin
      Logger.log(Logger.ERROR, "Exception: Addr: " & Integer'Image( To_Integer( location ) ) & ", line  " & Integer'Image( line ) );
      boot;
   end Last_Chance_Handler;


end Crash;
