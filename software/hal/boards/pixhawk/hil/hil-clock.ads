
with Ada.Real_Time;

package HIL.Clock with
   SPARK_Mode
is

   procedure configure;

   -- get number of systicks since POR
   function getSysTick return Natural;

   -- get system time since POR
   function getSysTime return Ada.Real_Time.Time;

end HIL.Clock;
