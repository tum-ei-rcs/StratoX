--  Project: StratoX
--  System:  Stratosphere Balloon Flight Controller
--  Author:  Martin Becker (becker@rcs.ei.tum.de)
with FAT_Filesystem.Directories.Files;
with Interfaces; use Interfaces;

--  @summary top-level package for reading/writing logfiles to SD card
package SDLog with SPARK_Mode,
  Abstract_State => State,
  Initializes => State
is

   subtype SDLog_Data is FAT_Filesystem.Directories.Files.File_Data;

   procedure Init with
     Post => Is_Open = False;
   --  initialize the SD log

   procedure Close with
     Post => Is_Open = False;
   --  closes the SD log

   procedure Start_Logfile
     (dirname : String; filename : String; ret : out Boolean);
   --  @summary create new logfile

   procedure Write_Log (Data : SDLog_Data; n_written : out Integer) with
     Pre => Is_Open;
   --  @summary write bytes to logfile

   procedure Write_Log (S : String; n_written : out Integer) with
     Pre => Is_Open;
   --  convenience function for Write_Log (File_Data)

   procedure Flush_Log;
   --  @summary force writing logfile to disk.
   --  Not recommended when time is critical!

   function Logsize return Unsigned_32;
   --  return log size in bytes

   function Is_Open return Boolean;
   --  return true if logfile is opened

   function To_File_Data (S : String) return SDLog_Data;

private
   log_open       : Boolean := False with Part_Of => State;
   SD_Initialized : Boolean := False with Part_Of => State;
   Error_State    : Boolean := False with Part_Of => State;

end SDLog;
