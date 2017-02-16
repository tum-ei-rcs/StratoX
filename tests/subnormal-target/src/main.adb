with Ada.Real_Time; use Ada.Real_Time;
with HIL.GPIO; use HIL.GPIO;
with HIL.Clock; use HIL.Clock;
with Crash;
pragma Unreferenced (Crash);
with Calc;

procedure main with SPARK_Mode is
   f1, f2, res : Float;

   next : Time := Clock;
   PERIOD : constant Time_Span := Milliseconds(500);
   led_on : Boolean := False;

begin
   HIL.Clock.configure;
   HIL.GPIO.configure;

   -- For the following tests, we have set system.Denorm (in RTS) to True

   -- Test1: Subnormal OUT FROM FPU: OKAY
   -- f1 := 0.00429291604;
   -- f2 := -2.02303554e-38;
   -- 0.00429291604*-2.02303554e-38 = -8.68468736e-41

   -- Test2: Subnormal INTO FPU: WORKS.
   f1 := 0.00429291604;
   f2 := -8.68468736e-41;  -- subnormal INTO FPU
   -- 0.00429291604*-8.68468736e-41 = -3.72745392e-43.

   res := Calc.calc (f1, f2); -- function call to force use of FPU

   loop

      if led_on then
         write (RED_LED, HIGH);
      else
         write (RED_LED, LOW);
      end if;

      led_on := not led_on;
      next := next + PERIOD;
      delay until next;

   end loop;

   res := 0.0;

end main;
