--  Project: StratoX
--  System:  Stratosphere Balloon Flight Controller
--  Author:  Martin Becker (becker@rcs.ei.tum.de)
with FAT_Filesystem.Directories.Files;
with Interfaces; use Interfaces;

--  @summary top-level package for reading/writing logfiles to SD card
package SDLog with SPARK_Mode => Off is

   procedure Init;
   --  initialize the SD log

   procedure Close;
   --  closes the SD log

   procedure List_Rootdir;
   --  example copied from AdaCore/Ada_Drivers_Library

   function Start_Logfile (dirname : String; filename : String) return Boolean;
   --  @summary create new logfile

   procedure Write_Log (Data : FAT_Filesystem.Directories.Files.File_Data);
   --  @summary write bytes to logfile

   procedure Write_Log (S : String);
   --  convenience function for Write_Log (File_Data)

   procedure Flush_Log;
   --  @summary force writing logfile to disk. Not recommended when time is critical!

   function Logsize return Unsigned_32;
   --  return log size in bytes

   function To_File_Data (S : String) return FAT_Filesystem.Directories.Files.File_Data;
end SDLog;
