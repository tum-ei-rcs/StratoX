with System.Machine_Reset;
with Ada.Real_Time;           use Ada.Real_Time;
with System.Task_Primitives.Operations;
with Config.Tasking;
with Bounded_Image; use Bounded_Image;

with Logger;
with NVRAM;
with HIL;
with Interfaces; use Interfaces;
with Unchecked_Conversion;

--  @summary Catches all exceptions, logs them to NVRAM and reboots.
package body Crash with SPARK_Mode => Off is
   --  XXX! SPARK must be off here, otherwise this function is not being implemented.
   --  Reasons see below.

   function To_Unsigned is new Unchecked_Conversion (System.Address, Unsigned_32);

   --  SPARK RM 6.5.1: a call to a non-returning procedure introduces the
   --  obligation to prove that the statement will not be executed.
   --  This is the same as a run-time check that fails unconditionally.
   --  RM 11.3: ...must provably never be executed.
   procedure Last_Chance_Handler(location : System.Address; line : Integer) is
      now    : constant Time := Clock;
      line16 : constant Unsigned_16 := (if line >= 0 and line <= Integer (Unsigned_16'Last)
                               then Unsigned_16 (line)
                               else Unsigned_16'Last);
   begin

      --  if the task which called this handler is not flight critical,
      --  silently hang here. as an effect, the system lives on without this task.
      declare
         use System.Task_Primitives.Operations;
         prio : constant ST.Extended_Priority := Get_Priority (Self);
      begin
         if prio < Config.Tasking.TASK_PRIO_FLIGHTCRITICAL then
            Logger.log (Logger.ERROR, "Non-critical task crashed");
            loop
               null;
            end loop;
            --  FIXME: there exists a "sleep infinite" procedure...just can't find it
            --  but that'll do. at least it doesn't block flight-critical tasks
         end if;
      end;

      --  first log to NVRAM
      declare
         ba : constant HIL.Byte_Array := HIL.toBytes (line16);
      begin
         NVRAM.Store (NVRAM.VAR_EXCEPTION_LINE_L, ba (1));
         NVRAM.Store (NVRAM.VAR_EXCEPTION_LINE_H, ba (2));
         NVRAM.Store (NVRAM.VAR_EXCEPTION_ADDR_A, To_Unsigned (location));
      end;

      --  now write to console (which might fail)
      Logger.log (Logger.ERROR, "Exception: Addr: " & Unsigned_Img (To_Unsigned (location))
                  & ", line  " & Integer_Img (line));

      -- wait until write finished (interrupt based)
      delay until now + Milliseconds(80);

      --  DEBUG ONLY: hang here to let us read the console output
--        loop
--           null;
--        end loop;

      --  XXX! A last chance handler must always terminate or suspend the
      --  thread that executes the handler. Suspending cannot be used here,
      --  because we cannot distinguish the tasks (?). So we reboot.

      --  Abruptly stop the program.
      --  On bareboard platform, this returns to the monitor or reset the board.
      --  In the context of an OS, this terminates the process.
      System.Machine_Reset.Stop; -- this is a non-returning function. SPARK assumes it is never executed.

      --  The following junk raise of Program_Error is required because
      --  this is a No_Return function, and unfortunately Suspend can
      --  return (although this particular call won't).

      raise Program_Error;

   end Last_Chance_Handler;

end Crash;
