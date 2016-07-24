--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with FAT_Filesystem;
with FAT_Filesystem.Directories; use FAT_Filesystem.Directories;

package FAT_Filesystem.Directories.Files with SPARK_Mode is

   type File_Handle is private;

   type File_Mode is (Read_Mode, Write_Mode);

   subtype File_Data is Block;

   function File_Create
     (Parent  : in out Directory_Handle;
      newname : String;
      File    : out File_Handle) return Status_Code;

   function File_Write
     (File : in out File_Handle;
      Data : File_Data) return Integer;
   --  @return number of bytes written (at most Data'Length), or -1 on error.

   function File_Read
     (File : in out File_Handle;
      Data : out File_Data) return Integer;
   --  @return number of bytes read (at most Data'Length), or -1 on error.

   procedure File_Close (File : in out File_Handle);
   --  invalidates the handle, and ensures that
   --  everything is flushed to the disk

private
   pragma SPARK_Mode (Off);

   type File_Handle is record
      Is_Open             : Boolean := False;
      FS                  : FAT_Filesystem_Access;
      Mode                : File_Mode := Read_Mode;
      Start_Cluster       : Unsigned_32 := INVALID_CLUSTER; -- first cluster; file begin
      Current_Cluster     : Unsigned_32 := 0; -- where we are currently reading/writing
      Current_Block       : Unsigned_32 := 0; -- same, but block
      Buffer              : File_Data (1 .. 512); --  size of one block in FAT/SD card
      Buffer_Level        : Natural := 0; -- how much data in Buffer is meaningful
      Bytes_Total         : Unsigned_32 := 0; -- how many bytes were read/written
   end record;
   --  used to access files
end FAT_Filesystem.Directories.Files;
