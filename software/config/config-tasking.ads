with System;

--  @summary all parameters for task/thread handling go here
package Config.Tasking is

   TASK_PRIO_FLIGHTCRITICAL : constant := System.Priority'First + 50;
   --  tasks below that value can crash, and they are ignored by then
   --  tasks above are so critical that we need a reboot if they crash

   TASK_PRIO_MAIN    : constant := TASK_PRIO_FLIGHTCRITICAL + 1;
   TASK_PRIO_LOGGING : constant := TASK_PRIO_FLIGHTCRITICAL - 10;

end Config.Tasking;
