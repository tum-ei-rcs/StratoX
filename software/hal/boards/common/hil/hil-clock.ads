--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with HIL.Devices;
with Ada.Real_Time;

--  @summary
--  Target-independent specification for HIL of Clock
package HIL.Clock with
   SPARK_Mode
is

   procedure configure;

   -- get number of systicks since POR
   function getSysTick return Natural;

   -- get system time since POR
   function getSysTime return Ada.Real_Time.Time;

end HIL.Clock;
