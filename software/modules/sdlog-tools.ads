--  Project: StratoX
--  System:  Stratosphere Balloon Flight Controller
--  Author:  Martin Becker (becker@rcs.ei.tum.de)

--  @summary tools for SD Logging
package SDLog.Tools with SPARK_Mode => Off is

   procedure Perf_Test (FS : in FAT_Filesystem.FAT_Filesystem_Access;
                        megabytes : Interfaces.Unsigned_32);
   --  Write performance test. Creates a file with the given length
   --  dumps throughput.

   procedure List_Rootdir (FS : in FAT_Filesystem.FAT_Filesystem_Access);

end SDLog.Tools;
