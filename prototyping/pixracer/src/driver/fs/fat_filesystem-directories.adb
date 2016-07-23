with Ada.Unchecked_Conversion;

package body FAT_Filesystem.Directories is

   -------------------------
   -- Open_Root_Directory --
   -------------------------

   function Open_Root_Directory
     (FS  : FAT_Filesystem_Access;
      Dir : out Directory_Handle) return Status_Code
   is

   begin
      if FS.Version = FAT16 then
         Dir.Start_Cluster   := 0;
         Dir.Current_Block   :=
           Unsigned_32 (FS.Reserved_Blocks) +
           FS.FAT_Table_Size_In_Blocks *
             Unsigned_32 (FS.Number_Of_FATs);
      else
         Dir.Start_Cluster := FS.Root_Dir_Cluster;
         Dir.Current_Block := FS.Cluster_To_Block (FS.Root_Dir_Cluster);
      end if;

      Dir.FS := FS;
      Dir.Current_Cluster := Dir.Start_Cluster;
      Dir.Current_Index   := 0;

      return OK;
   end Open_Root_Directory;

   function Allocate_Entry
     (Parent  : Directory_Entry;
      Ent     : out Directory_Entry) return Status_Code
   is
      c            : Unsigned_32;
      need_cluster : Boolean;
      need_block   : Boolean;
      Ret          : Status_Code;
      Block_Off    : Unsigned_16;
      Handle       : Directory_Handle;
   begin
      if Parent.FS.Version /= FAT32 then
         --  we only support FAT32 for now.
         return Internal_Error;
      end if;

      --  get handle from entry
      if Open (Parent, Handle) /= OK then
         return Invalid_Object_Entry;
      end if;

      Ret := Handle.FS.Ensure_Block (Handle.Current_Block);
      if Ret /= OK then
         return Ret;
      end if;

      need_cluster := False;
      --  go to the last directory entry
      Find_Last : loop
         Block_Off :=
           Unsigned_16
             (Unsigned_32 (Handle.Current_Index) * 32
              mod Parent.FS.Block_Size_In_Bytes);
         --  offset of entry within current block

         --  do we need to fetch the next block?
         if Handle.Current_Index > 0
           and then Block_Off = 0
         then
            Handle.Current_Block := Handle.Current_Block + 1;
            --  do we need to fetch the next cluster?
            if Handle.Current_Block -
              Handle.FS.Cluster_To_Block (Handle.Current_Cluster) =
              Unsigned_32 (Handle.FS.Number_Of_Blocks_Per_Cluster)
            then
               Handle.Current_Cluster := Handle.FS.Get_FAT (Handle.Current_Cluster);

               if Handle.Current_Cluster = INVALID_CLUSTER or
                  Handle.FS.Is_Last_Cluster (Handle.Current_Cluster) then
                  return Internal_Error;
               end if;

               Handle.Current_Block :=
                 Handle.FS.Cluster_To_Block (Handle.Current_Cluster);
            end if;

            --  read next block
            Ret := Handle.FS.Ensure_Block (Handle.Current_Block);

            if Ret /= OK then
               return Ret;
            end if;
         end if;

         --  are we at the end of the entries?
         if Handle.FS.Window (Block_Off) = 0 then
            Handle.Current_Index := 16#FFFF#;
            return Too_Many_Entries;
         end if;

         --  okay, there are more entries. each entry is 32bytes:
         --  Ent := To_Entry (Dir.FS.Window (Block_Off .. Block_Off + 31));
         Handle.Current_Index := Handle.Current_Index + 1;
      end loop Find_Last;

      need_block := False;

      --  if we are here, then we reached the last entry in the directory.
      --  see whether block_off is small enough to accommodate another entry
      --  block_Off .. Block_Off + 31 must be available, otherwise we need a
      --  the next block
      need_cluster := need_block and False; -- TODO

      --  if the next block is still in the cluster, then just continue writing.
      --  otherwise we have to allocate a new cluster
      if need_cluster then

         --  find free cluster
         c := Parent.FS.Get_Free_Cluster;
         if c = INVALID_CLUSTER then
            return Device_Full;
         end if;

         --  allocate it
         if not Parent.FS.Allocate_Cluster (c) then
            return Allocation_Error;
         end if;
      else
         c := Parent.Start_Cluster;
      end if;

      --  now add the new

      return OK;
   end Allocate_Entry;

   function Make_Directory
     (Parent  : in Directory_Entry;
      newname : String;
      Dir     : out Directory_Handle) return Status_Code
   is
      Ent : Directory_Entry;
   begin
      if Parent.FS.Version /= FAT32 then
         --  we only support FAT32 for now.
         return Internal_Error;
      end if;

      --  find a place for another entry and return it
      if Allocate_Entry (Parent, Ent) /= OK then
         return Allocation_Error;
      end if;

      --  TODO: fill entry attrs to make it a directory
      --  read the block where the new entry goes
      --  copy over to FS.Window
      --  write back the block with the new entry

      return OK;
   end Make_Directory;

   ----------
   -- Open --
   ----------

   function Open
     (E   : Directory_Entry;
      Dir : out Directory_Handle) return Status_Code
   is
   begin
      Dir.Start_Cluster := E.Start_Cluster;
      Dir.Current_Block := E.FS.Cluster_To_Block (E.Start_Cluster);
      Dir.FS := E.FS;
      Dir.Current_Cluster := Dir.Start_Cluster;
      Dir.Current_Index   := 0;

      return OK;
   end Open;

   -----------
   -- Close --
   -----------

   procedure Close (Dir : in out Directory_Handle)
   is
   begin
      Dir.FS              := null;
      Dir.Current_Index   := 0;
      Dir.Start_Cluster   := 0;
      Dir.Current_Cluster := 0;
      Dir.Current_Block   := 0;
   end Close;

   --  @summary decypher the raw entry (file/dir name, etc) and write
   --           to record.
   --  @return OK when decipher is complete, otherwise needs to be
   --          called again with the next entry (VFAT entries have
   --          multiple parts)
   function FAT_To_Directory_Entry
     (FS : FAT_Filesystem_Access;
      F_Entry : in FAT_Directory_Entry;
      DEntry : in out Directory_Entry;
      Last_Seq : in out VFAT_Sequence_Number) return Status_Code
   is
      procedure Prepend
        (VName : Wide_String;
         Full : in out String;
         Idx  : in out Natural);

      procedure Prepend
        (VName : Wide_String;
         Full : in out String;
         Idx  : in out Natural)
      is
         Val : Unsigned_16;
      begin
         for J in reverse VName'Range loop
            Val := Wide_Character'Pos (VName (J));
            if Val /= 16#FFFF#
              and then Val /= 0
            then
               Idx := Idx - 1;

               exit when Idx not in Full'Range;

               if Val < 255 then
                  Full (Idx) := Character'Val (Val);
               else
                  Full (Idx) := '?';
               end if;
            end if;
         end loop;
      end Prepend;

      function To_VFAT_Entry is new Ada.Unchecked_Conversion
        (FAT_Directory_Entry, VFAT_Directory_Entry);

      CRC         : Unsigned_8 := 0;
      Matches     : Boolean;
      Current_CRC : Unsigned_8;
      V_Entry     : VFAT_Directory_Entry;
      C           : Unsigned_8;
   begin
      if F_Entry.Attributes = VFAT_Directory_Entry_Attribute then
         V_Entry := To_VFAT_Entry (F_Entry);

         if V_Entry.VFAT_Attr.Stop_Bit then
            DEntry.L_Name_First := DEntry.L_Name'Last + 1;
            Last_Seq := 0;

         else
            if Last_Seq = 0
              or else Last_Seq - 1 /= V_Entry.VFAT_Attr.Sequence
            then
               DEntry.L_Name_First := DEntry.L_Name'Last + 1;
            end if;

            Last_Seq := V_Entry.VFAT_Attr.Sequence;

            Prepend (V_Entry.Name_3, DEntry.L_Name, DEntry.L_Name_First);
            Prepend (V_Entry.Name_2, DEntry.L_Name, DEntry.L_Name_First);
            Prepend (V_Entry.Name_1, DEntry.L_Name, DEntry.L_Name_First);

            if V_Entry.VFAT_Attr.Sequence = 1 then
               CRC := V_Entry.Checksum;
            end if;
         end if;
         --  VFAT needs more data...cannot return "OK", yet
      elsif not F_Entry.Attributes.Volume_Label --  Ignore Volumes
        and then Character'Pos (F_Entry.Filename (1)) /= 16#E5# --  Ignore deleted files
      then
         --  any other entry, which we return with "OK".
         if DEntry.L_Name_First not in DEntry.L_Name'Range then
            Matches := False;
         else
            Current_CRC := 0;
            Last_Seq := 0;

            for Ch of String'(F_Entry.Filename & F_Entry.Extension) loop
               C := Character'Enum_Rep (Ch);
               Current_CRC := Shift_Right (Current_CRC and 16#FE#, 1)
                 or Shift_Left (Current_CRC and 16#01#, 7);
               --  Modulo addition
               Current_CRC := Current_CRC + C;
            end loop;

            Matches := Current_CRC = CRC;
         end if;

         declare
            Base   : String renames Trim (F_Entry.Filename);
            Ext    : String renames Trim (F_Entry.Extension);
            S_Name : constant String :=
              Base &
            (if Ext'Length > 0
             then "." & Trim (F_Entry.Extension)
             else "");
         begin
            DEntry.S_Name (1 .. S_Name'Length) := S_Name;
            DEntry.S_Name_Last := S_Name'Length;
         end;

         DEntry.Attributes    := F_Entry.Attributes;
         DEntry.Start_Cluster := Unsigned_32 (F_Entry.Cluster_L);
         DEntry.Size          := F_Entry.Size;
         DEntry.FS            := FS;

         if FS.Version = FAT32 then
            DEntry.Start_Cluster :=
              DEntry.Start_Cluster or
              Shift_Left (Unsigned_32 (F_Entry.Cluster_H), 16);
         end if;

         if not Matches then
            DEntry.L_Name_First := DEntry.L_Name'Last + 1;
         end if;

         return OK; -- finished fetching next entry
      end if;
      return Invalid_Name;
   end FAT_To_Directory_Entry;

   ----------
   -- Read --
   ----------

   function Read (Dir    : in out Directory_Handle;
                  DEntry : out Directory_Entry) return Status_Code
   is


      Ret     : Status_Code;
      F_Entry : FAT_Directory_Entry;
      subtype Entry_Data is Block (1 .. 32);
      function To_Entry is new Ada.Unchecked_Conversion
        (Entry_Data, FAT_Directory_Entry);

      Last_Seq    : VFAT_Sequence_Number := 0;
      Block_Off   : Unsigned_16;
   begin
      if Dir.Start_Cluster = 0
        and then Dir.Current_Index >= Dir.FS.Number_Of_Entries_In_Root_Dir
      then
         return Invalid_Object_Entry;
      elsif Dir.Current_Index = 16#FFFF# then
         return Invalid_Object_Entry;
      end if;

      Ret := Dir.FS.Ensure_Block (Dir.Current_Block);
      if Ret /= OK then
         return Ret;
      end if;

      DEntry.L_Name_First := DEntry.L_Name'Last + 1;

      Fetch_Next : loop
         Block_Off :=
           Unsigned_16
             (Unsigned_32 (Dir.Current_Index) * 32
              mod Dir.FS.Block_Size_In_Bytes);
         --  offset of entry within current block

         --  do we need to fetch the next block?
         if Dir.Current_Index > 0
           and then Block_Off = 0
         then
            Dir.Current_Block := Dir.Current_Block + 1;
            --  do we need to fetch the next cluster?
            if Dir.Current_Block -
              Dir.FS.Cluster_To_Block (Dir.Current_Cluster) =
              Unsigned_32 (Dir.FS.Number_Of_Blocks_Per_Cluster)
            then
               Dir.Current_Cluster := Dir.FS.Get_FAT (Dir.Current_Cluster);

               if Dir.Current_Cluster = INVALID_CLUSTER
                 or else Dir.FS.Is_Last_Cluster (Dir.Current_Cluster)
               then
                  return Internal_Error;
               end if;

               Dir.Current_Block :=
                 Dir.FS.Cluster_To_Block (Dir.Current_Cluster);
            end if;

            --  read next block
            Ret := Dir.FS.Ensure_Block (Dir.Current_Block);

            if Ret /= OK then
               return Ret;
            end if;
         end if;

         --  are we at the end of the entries?
         if Dir.FS.Window (Block_Off) = 0 then
            Dir.Current_Index := 16#FFFF#;
            return Invalid_Object_Entry;
         end if;

         --  okay, there are more entries. each entry is 32bytes:
         F_Entry := To_Entry (Dir.FS.Window (Block_Off .. Block_Off + 31));
         Dir.Current_Index := Dir.Current_Index + 1;

         --  continue until we have an entry...because VFAT has multiple parts
         if FAT_To_Directory_Entry (Dir.FS, F_Entry, DEntry, Last_Seq) = OK then
            exit Fetch_Next;
         end if;

      end loop Fetch_Next;
      return OK;
   end Read;

   ----------
   -- Name --
   ----------

   function Name (E : Directory_Entry) return String
   is
   begin
      if E.L_Name_First in E.L_Name'Range then
         return E.L_Name (E.L_Name_First .. E.L_Name'Last);
      else
         return E.S_Name (E.S_Name'First .. E.S_Name_Last);
      end if;
   end Name;

end FAT_Filesystem.Directories;
