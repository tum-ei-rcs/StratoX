with System.Machine_Reset;
with Ada.Real_Time; use Ada.Real_Time;

with Logger;
--with Boot;
with NVRAM;
with HIL;
with Interfaces; use Interfaces;
with Unchecked_Conversion;

--  @summary Catches all exceptions, logs them to NVRAM and reboots.
package body Crash with SPARK_Mode is

   function To_Integer is new Unchecked_Conversion (System.Address, Integer);

   procedure Last_Chance_Handler(location : System.Address; line : Integer) is
      now    : constant Time := Clock;
      line16 : constant Unsigned_16 := (if line >= 0 and line <= Integer (Unsigned_16'Last)
                               then Unsigned_16 (line)
                               else Unsigned_16'Last);
   begin
      --  first log to NVRAM
      declare
         ba : constant HIL.Byte_Array := HIL.toBytes (line16);
      begin
         NVRAM.Store(NVRAM.VAR_EXCEPTION_LINE_L,  ba (1) );
         NVRAM.Store(NVRAM.VAR_EXCEPTION_LINE_H,  ba (2) );
      end;

      --  now write to console (which might fail)
      Logger.log_console(Logger.ERROR, "Exception: Addr: "
                         & Integer'Image( To_Integer( location ) )
                         & ", line  " & Integer'Image( line ) );

      -- wait until write finished (interrupt based)
      delay until now + Milliseconds(80);

      --  Abruptly stop the program.
      --  On bareboard platform, this returns to the monitor or reset the board.
      --  In the context of an OS, this terminates the process.
      System.Machine_Reset.Stop;
   end Last_Chance_Handler;

end Crash;
