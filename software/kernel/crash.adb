

with Logger;
with System;
with Boot;

package body Crash is

   procedure Last_Chance_Handler(location : System.Address; line : Integer) is
   begin
      Logger.log(Logger.ERROR, "Exception: line " & Integer'Image( line ) );
      boot;
   end Last_Chance_Handler;


end Crash;
