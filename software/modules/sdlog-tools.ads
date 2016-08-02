--  Project: StratoX
--  System:  Stratosphere Balloon Flight Controller
--  Author:  Martin Becker (becker@rcs.ei.tum.de)
with Interfaces; use Interfaces;
with FAT_Filesystem.Directories;

--  @summary tools for SD Logging
package SDLog.Tools is

   procedure Perf_Test (megabytes : Unsigned_32);
   --  Write performance test. Creates a file with the given length
   --  dumps throughput.

   procedure List_Rootdir is
      Dir : Directory_Handle;
      Ent : Directory_Entry;

end SDLog.Tools;
