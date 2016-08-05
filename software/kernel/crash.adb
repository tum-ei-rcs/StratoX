

with System.Machine_Reset;
with Ada.Real_Time; use Ada.Real_Time;

with Logger;
with Boot;
with NVRAM;
with HIL;
with Interfaces; use Interfaces;


with Unchecked_Conversion;

package body Crash is

   function To_Integer is new Unchecked_Conversion (System.Address, Integer);


   procedure Last_Chance_Handler(location : System.Address; line : Integer) is
      now : Time := Clock;
   begin
      Logger.log_console(Logger.ERROR, "Exception: Addr: " & Integer'Image( To_Integer( location ) ) & ", line  " & Integer'Image( line ) );
      NVRAM.Store(NVRAM.VAR_EXCEPTION_LINE_L,  HIL.toBytes( Unsigned_16( line ) )(1) );
      NVRAM.Store(NVRAM.VAR_EXCEPTION_LINE_H,  HIL.toBytes( Unsigned_16( line ) )(2) );

      -- wait until write finished (interrupt based)
      delay until now + Milliseconds(80);

      --  Abruptly stop the program.
      --  On bareboard platform, this returns to the monitor or reset the board.
      --  In the context of an OS, this terminates the process.
      System.Machine_Reset.Stop;
   end Last_Chance_Handler;


end Crash;
