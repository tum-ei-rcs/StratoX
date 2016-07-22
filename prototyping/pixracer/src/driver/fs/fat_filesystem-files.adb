package body FAT_Filesystem.Files is

   function File_Create
     (Parent  : Directory_Handle;
      newname : String;
      File     : out File_Handle) return Status_Code is
   begin
      if Parent.FS.Version /= FAT32 then
         --  we only support FAT32 for now.
         return Internal_Error;
      end if;

      return OK;
   end File_Create;

end FAT_Filesystem.Files;
