

with Logger;
with Boot;
with NVRAM;
with HIL;
with Interfaces; use Interfaces;

with Unchecked_Conversion;

package body Crash is

   function To_Integer is new Unchecked_Conversion (System.Address, Integer);


   procedure Last_Chance_Handler(location : System.Address; line : Integer) is
   begin
      Logger.log(Logger.ERROR, "Exception: Addr: " & Integer'Image( To_Integer( location ) ) & ", line  " & Integer'Image( line ) );
      NVRAM.Store(NVRAM.VAR_EXCEPTION_LINE_L,  HIL.toBytes( Unsigned_16( line ) )(1) );
      NVRAM.Store(NVRAM.VAR_EXCEPTION_LINE_H,  HIL.toBytes( Unsigned_16( line ) )(2) );
      Boot; -- if exception occurs in protected object, calls will be nested => Blocking Exception Loop
   end Last_Chance_Handler;


end Crash;
