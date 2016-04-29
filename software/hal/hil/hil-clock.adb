
with Ada.Real_Time;
with STM32.Device;

package body HIL.Clock is

   procedure configure is
   begin
   STM32.Device.Enable_Clock();
   end configure;
   
   

   -- get number of systicks since POR
   function getSysTick return Natural;

   -- get system time since POR
   function getSysTime return Ada.Real_Time.Time;

end HIL.Clock;
