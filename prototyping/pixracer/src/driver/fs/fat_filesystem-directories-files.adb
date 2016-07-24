with Ada.Unchecked_Conversion;
with FAT_Filesystem; use FAT_Filesystem;

package body FAT_Filesystem.Directories.Files is

   function File_Create
     (Parent  : in out Directory_Handle;
      newname : String;
      File    : out File_Handle) return Status_Code
   is
      subtype Entry_Data is Block (1 .. 32);
      function From_Entry is new Ada.Unchecked_Conversion
        (FAT_Directory_Entry, Entry_Data);

      F_Entry  : FAT_Directory_Entry;
      Ent_Addr : FAT_Address;
      Status   : Status_Code;
      D_Entry  : Directory_Entry;
      new_cluster : Unsigned_32;
   begin
      File.Is_Open := False;
      if Parent.FS.Version /= FAT32 then
         --  we only support FAT32 for now.
         return Internal_Error;
      end if;

      --  find a place for another entry and return it
      Status := Allocate_Entry (Parent, newname, Ent_Addr);
      if Status /= OK then
         return Status;
      end if;

      --  find free cluster
      new_cluster := Parent.FS.Get_Free_Cluster;
      if new_cluster = INVALID_CLUSTER then
         return Device_Full;
      end if;

      --  allocate first cluster for data
      if not Parent.FS.Allocate_Cluster (new_cluster)
      then
         return Allocation_Error;
      end if;

      --  read complete block to write the entry
      Status := Parent.FS.Ensure_Block (Ent_Addr.Block_LBA);
      if Status /= OK then
         return Status;
      end if;

      --  fill entry attrs to make it a directory
      D_Entry.FS := Parent.FS;
      D_Entry.Attributes.Read_Only := False;
      D_Entry.Attributes.Hidden := False;
      D_Entry.Attributes.Archive := False;
      D_Entry.Attributes.System_File := True;
      D_Entry.Attributes.Volume_Label := False;
      D_Entry.Attributes.Subdirectory := False;
      D_Entry.Start_Cluster := new_cluster;
      D_Entry.Size := 0;  -- right now...zero. Has to be maintained somehow.

      --  FIXME: 8+3 scheme
      StrCpySpace (instring => newname, outstring => D_Entry.Short_Name);

      D_Entry.Short_Name_Last := D_Entry.Short_Name'Length;
      D_Entry.Long_Name_First := D_Entry.Long_Name'Last + 1;

      --  encode into FAT entry
      Status := Directory_To_FAT_Entry (D_Entry, F_Entry);
      if Status /= OK then
         return Status;
      end if;

      --  copy entry to window
      Parent.FS.Window (Ent_Addr.Block_Off .. Ent_Addr.Block_Off +
                          ENTRY_SIZE - 1) := From_Entry (F_Entry);

      --  write back the window to disk
      Status := Parent.FS.Write_Window (Ent_Addr.Block_LBA);
      if Status /= OK then
         return Status;
      end if;

      --  set up file handle
      File.FS := Parent.FS;
      File.Start_Cluster := new_cluster;
      File.Current_Cluster := new_cluster;
      File.Current_Block := Parent.FS.Cluster_To_Block (new_cluster);
      File.Buffer_Level := 0;
      File.Mode := Write_Mode;
      File.Bytes_Total := 0;
      File.Is_Open := True;
      return OK;
   end File_Create;

   function File_Write
     (File : in out File_Handle;
      Data : File_Data) return Integer
   is
   begin
      if not File.Is_Open or File.Mode /= Write_Mode then
         return -1;
      end if;

      --  TODO: write to buffer. If buffer is full, write to disk
      File.Bytes_Total := File.Bytes_Total + Data'Length;
      return -1;
   end File_Write;

   function File_Read
     (File : in out File_Handle;
      Data : out File_Data) return Integer is
   begin
      if not File.Is_Open or File.Mode /= Read_Mode then
         return -1;
      end if;

      --  TODO: read from buffer. If buffer is empty, read from disk.
      File.Bytes_Total := File.Bytes_Total + 0; -- TODO
      return -1;
   end File_Read;

   procedure File_Close (File : in out File_Handle) is
   begin
      if not File.Is_Open then
         return;
      end if;

      if File.Mode = Write_Mode then
         --  TODO: flush window to disk
         File.FS.Window := File.Buffer;
         declare
            Status : Status_Code := File.FS.Write_Window (File.Current_Block);
            pragma Unreferenced (Status);
         begin
            null;
         end;
         --  TODO: update directory entry.size with File.Bytes_Total
      end if;

      File.Is_Open := False;
   end File_Close;

end FAT_Filesystem.Directories.Files;
