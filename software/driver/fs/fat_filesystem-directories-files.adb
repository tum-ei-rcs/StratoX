--  Project: StratoX
--  System:  Stratosphere Balloon Flight Controller
--  Author: Martin Becker (becker@rcs.ei.tum.de)
--  XXX! Nothing here is thread-safe!

with Ada.Unchecked_Conversion;
with FAT_Filesystem; use FAT_Filesystem;

--  @summary File handling for FAT FS
package body FAT_Filesystem.Directories.Files is

   -------------------
   --  File_Create
   -------------------

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

      --  find free cluster or data
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
      File.D_Entry.FS := Parent.FS;
      File.D_Entry.Attributes.Read_Only := False;
      File.D_Entry.Attributes.Hidden := False;
      File.D_Entry.Attributes.Archive := True; -- for backup: mark new files with archive flag
      File.D_Entry.Attributes.System_File := False;
      File.D_Entry.Attributes.Volume_Label := False;
      File.D_Entry.Attributes.Subdirectory := False;
      File.D_Entry.Start_Cluster := new_cluster;
      File.D_Entry.Entry_Address := Ent_Addr;
      File.D_Entry.Size := 0; -- file is empty, yet
      Set_Name (newname, File.D_Entry);

      --  encode into FAT entry
      Status := Directory_To_FAT_Entry (File.D_Entry, F_Entry);
      if Status /= OK then
         return Status;
      end if;

      --  copy FAT entry to window
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

   -------------------
   --  Update_Entry
   -------------------

   function Update_Entry (File : in out File_Handle) return Status_Code is
      Status : Status_Code;
   begin
      Status := File.FS.Ensure_Block (File.D_Entry.Entry_Address.Block_LBA);
      if Status /= OK then
         return Status;
      end if;

      --  a bit of a hack, to save us from the work of re-generating the entire entry
      declare
         Size_Off : constant Unsigned_16 := 28;
         subtype Entry_Data is Block (1 .. 4);
         function Bytes_From_Size is new Ada.Unchecked_Conversion
           (Unsigned_32, Entry_Data);

         win_lo : constant Unsigned_16 := File.D_Entry.Entry_Address.Block_Off + Size_Off;
         win_hi : constant Unsigned_16 := win_lo + 3;
      begin
         File.FS.Window (win_lo .. win_hi) := Bytes_From_Size (File.D_Entry.Size);
      end;

      Status := File.FS.Write_Window (File.D_Entry.Entry_Address.Block_LBA);
      return Status;
   end Update_Entry;

   -------------------
   --  File_Write
   -------------------

   function File_Write
     (File   : in out File_Handle;
      Data   : File_Data;
      Status : out Status_Code) return Integer
   is
      newlevel    : Natural := 0;
      n_processed : Natural := 0;
      this_chunk  : Natural := 0;
   begin
      if not File.Is_Open or File.Mode /= Write_Mode then
         return -1;
      end if;

      if Data'Length < 1 then
         return 0;
      end if;

      --  if buffer is full, write to disk
      Write_Loop : loop
         --  determine how much the buffer can take
         declare
            n_remain : constant Natural := Data'Length - n_processed;
            cap      : Natural;
         begin
            cap := File.Buffer'Length - File.Buffer_Level;
            this_chunk := (if cap >= n_remain then n_remain else cap);
            newlevel := File.Buffer_Level + this_chunk;
         end;

         --  copy max amount to buffer.
         declare
            buf_lo : constant Unsigned_16 := File.Buffer'First + Unsigned_16 (File.Buffer_Level);
            buf_hi : constant Unsigned_16 := File.Buffer'First + Unsigned_16 (newlevel) - 1;
            cnk_lo : constant Unsigned_16 := Data'First + Unsigned_16 (n_processed);
            cnk_hi : constant Unsigned_16 := cnk_lo + Unsigned_16 (this_chunk) - 1;
         begin
            File.Buffer (buf_lo .. buf_hi) := Data (cnk_lo .. cnk_hi);
         end;

         --  book keeping
         File.Bytes_Total := File.Bytes_Total + Unsigned_32 (this_chunk);
         File.D_Entry.Size := File.Bytes_Total;

         --  write buffer to disk only if full
         if File.Buffer_Level = File.Buffer'Length then
            File.FS.Window := File.Buffer;
            Status := File.FS.Write_Window (File.Current_Block);
            if Status /= OK then
               return n_processed;
            end if;

            --  now check whether the next block fits in the cluster.
            --  Otherwise alloc next cluster and update FAT.
            File.Current_Block := File.Current_Block + 1;
            if File.Current_Block - File.FS.Cluster_To_Block (File.Current_Cluster) =
              Unsigned_32 (File.FS.Number_Of_Blocks_Per_Cluster)
            then
               --  require another cluster
               declare
                  New_Cluster : Unsigned_32;
               begin
                  Status := File.FS.Append_Cluster
                    (Last_Cluster => File.Current_Cluster,
                     New_Cluster => New_Cluster);
                  if Status /= OK then
                     return n_processed;
                  end if;
                  File.Current_Cluster := New_Cluster;
                  File.Current_Block := File.FS.Cluster_To_Block (File.Current_Cluster);
               end;
            end if;
            File.Buffer_Level := 0; -- now it is empty

            --  update directory entry on disk (size has changed)
            declare
               Status_Up : Status_Code := Update_Entry (File);
               pragma Unreferenced (Status_Up); -- don't care, that size is optional for us
            begin
               null;
            end;
         else
            File.Buffer_Level := newlevel;
         end if;

         n_processed := n_processed + this_chunk;
         exit Write_Loop when n_processed = Data'Length;
      end loop Write_Loop;

      return n_processed;
   end File_Write;

   ------------------------
   --  File_Open_Readonly
   ------------------------

   function File_Open_Readonly
     (Ent  : in out Directory_Entry;
      File : in out File_Data) return Status_Code
   is
      pragma Unreferenced (Ent, File);
   begin
      --  TODO: not yet implemented
      return Internal_Error;
   end File_Open_Readonly;

   ---------------
   --  File_Read
   ---------------

   function File_Read
     (File : in out File_Handle;
      Data : out File_Data) return Integer
   is
      pragma Unreferenced (Data);
   begin
      if not File.Is_Open or File.Mode /= Read_Mode then
         return -1;
      end if;

      --  TODO: not yet implemented
      File.Bytes_Total := File.Bytes_Total + 0;
      return -1;
   end File_Read;

   ----------------
   --  File_Close
   ----------------

   procedure File_Close (File : in out File_Handle) is
   begin
      if not File.Is_Open then
         return;
      end if;

      if File.Mode = Write_Mode and then File.Buffer_Level > 0 then
         --  flush buffer to disk
         File.FS.Window := File.Buffer;
         declare
            Status : Status_Code := File.FS.Write_Window (File.Current_Block);
            pragma Unreferenced (Status);
         begin
            null;
         end;
         --  we assume that the directory entry is already maintained by File_Write
      end if;
      File.Is_Open := False;
   end File_Close;

   ----------------
   --  File_Flush
   ----------------

   function File_Flush (File : in out File_Handle) return Status_Code is
      Status : Status_Code;
   begin
      if not File.Is_Open then
         return Invalid_Object_Entry;
      end if;

      if File.Mode = Write_Mode and then File.Buffer_Level > 0 then
         --  flush data block, even if not full
         File.FS.Window := File.Buffer;
         Status := File.FS.Write_Window (File.Current_Block);

         --  force-update directory entry on disk
         declare
            Status_Up : Status_Code := Update_Entry (File);
            pragma Unreferenced (Status_Up); -- don't care, that size is optional for us
         begin
            null;
         end;
      end if;

      return Status;
   end File_Flush;

   ----------------
   --  File_Size
   ----------------

   function File_Size (File : File_Handle) return Unsigned_32 is (File.Bytes_Total);

end FAT_Filesystem.Directories.Files;
