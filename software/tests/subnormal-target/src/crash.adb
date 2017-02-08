with Ada.Real_Time; use Ada.Real_Time;
with HIL.GPIO; use HIL.GPIO;

package body Crash is

   procedure Last_Chance_Handler
     (Source_Location : System.Address; Line : Integer) is
      next : Time := Clock;
      PERIOD : constant Time_Span := Milliseconds(1000);
   begin
      write (RED_LED, HIGH);
      loop
         next := next + PERIOD;
         delay until next;
      end loop;
   end Last_Chance_Handler;

end Crash;
