--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Martin Becker (becker@rcs.ei.tum.de)
with FAT_Filesystem;

package FAT_Filesystem.Files with SPARK_Mode is

   type File_Handle is private;

   function File_Create
     (Parent  : Directory_Handle;
      newname : String;
      File     : out File_Handle) return Status_Code;


private
   pragma SPARK_Mode (Off);

   type File_Handle is record
      FS              : FAT_Filesystem_Access;
      Current_Index   : Unsigned_16;
      Start_Cluster   : Unsigned_32;
      Current_Cluster : Unsigned_32;
      Current_Block   : Unsigned_32;
   end record;
   -- used to access files
end FAT_Filesystem.Files;
