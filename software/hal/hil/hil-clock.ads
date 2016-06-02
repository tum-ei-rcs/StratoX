
pragma SPARK_Mode(Off);

with Ada.Real_Time;

package HIL.Clock is

   procedure configure;

   -- get number of systicks since POR
   function getSysTick return Natural;

   -- get system time since POR
   function getSysTime return Ada.Real_Time.Time;

end HIL.Clock;
