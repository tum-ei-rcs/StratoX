--  Project: StratoX
--  System:  Stratosphere Balloon Flight Controller
--  Author: Martin Becker (becker@rcs.ei.tum.de)
with FAT_Filesystem.Directories.Files;

--  @summary read/write SD card using a file system
package SDMemory.Driver is
   procedure Init_Filesys;
   --  initialize the interface

   procedure Close_Filesys;
   --  closes the interface

   procedure List_Rootdir;
   --  example copied from AdaCore/Ada_Drivers_Library

   function Start_Logfile (dirname : String; filename : String) return Boolean;
   --  @summary create new logfile

   procedure Write_Log (Data : FAT_Filesystem.Directories.Files.File_Data);
   --  @summary write bytes to logfile

   function To_File_Data (S : String) return FAT_Filesystem.Directories.Files.File_Data;

end SDMemory.Driver;
