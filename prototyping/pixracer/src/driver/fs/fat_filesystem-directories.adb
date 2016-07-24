with Ada.Unchecked_Conversion;

package body FAT_Filesystem.Directories is

   -------------------------
   -- Open_Root_Directory --
   -------------------------

   ENTRY_SIZE : constant := 32;

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

   function Make_Directory
     (Parent  : in Directory_Entry;
      newname : String;
      D_Entry : out Directory_Entry) return Status_Code
   is
      subtype Entry_Data is Block (1 .. 32);
      function From_Entry is new Ada.Unchecked_Conversion
        (FAT_Directory_Entry, Entry_Data);

      F_Entry  : FAT_Directory_Entry;
      Ent_Addr : FAT_Address;
      Status   : Status_Code;

   begin
      if Parent.FS.Version /= FAT32 then
         --  we only support FAT32 for now.
         return Internal_Error;
      end if;

      --  find a place for another entry and return it
      Status := Allocate_Entry (Parent, newname, Ent_Addr);
      if Status /= OK then
         return Status;
      end if;

      --  read complete block
      Status := Parent.FS.Ensure_Block (Ent_Addr.Block_LBA);
      if Status /= OK then
         return Status;
      end if;

      --  fill entry attrs to make it a directory
      D_Entry.FS := Parent.FS;
      D_Entry.Attributes.Read_Only := False;
      D_Entry.Attributes.Hidden := False;
      D_Entry.Attributes.Archive := False;
      D_Entry.Attributes.System_File := False;
      D_Entry.Attributes.Volume_Label := False;
      D_Entry.Attributes.Subdirectory := True;
      D_Entry.Start_Cluster := Parent.FS.Block_To_Cluster (Ent_Addr.Block_LBA);
      D_Entry.Size := 0; -- directories always carry zero
      StrCpySpace (instring => newname, outstring => D_Entry.Short_Name);
      D_Entry.Short_Name_Last := D_Entry.Short_Name'Length;
      D_Entry.Long_Name_First := D_Entry.Long_Name'Last + 1;

      --  encode into FAT entry
      Status := Directory_To_FAT_Entry (D_Entry, F_Entry);
      if Status /= OK then
         return Status;
      end if;

      --  copy over to FS.Window
      Parent.FS.Window (Ent_Addr.Block_Off .. Ent_Addr.Block_Off + ENTRY_SIZE - 1)
        := From_Entry (F_Entry);

      --  write back the block with the new entry
      Status := Parent.FS.Write_Window (Ent_Addr.Block_LBA);

      --  TODO: create obligatory entries "." and ".."
      return Status;
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

   --  @summary encode Directory_Entry into FAT_Directory_Entry
   function Directory_To_FAT_Entry
     (D_Entry : in Directory_Entry;
      F_Entry : out FAT_Directory_Entry) return Status_Code
   is
   begin
      F_Entry.Date := 0; -- FIXME: set date/time
      F_Entry.Time := 0;
      F_Entry.Size := D_Entry.Size;
      F_Entry.Attributes := D_Entry.Attributes;
      Set_Shortname (Name (D_Entry), F_Entry);
      F_Entry.Cluster_L := Unsigned_16 (D_Entry.Start_Cluster and 16#FFFF#);
      if D_Entry.FS.Version = FAT16 then
         F_Entry.Cluster_H := 0;
      else
         F_Entry.Cluster_H := Unsigned_16 (Shift_Right
              (D_Entry.Start_Cluster and 16#FFFF_0000#, 16));
      end if;

      return OK;
   end Directory_To_FAT_Entry;

   --  @summary decypher the raw entry (file/dir name, etc) and write
   --           to record.
   --  @return OK when decipher is complete, otherwise needs to be
   --          called again with the next entry (VFAT entries have
   --          multiple parts)
   function FAT_To_Directory_Entry
     (FS : FAT_Filesystem_Access;
      F_Entry : in FAT_Directory_Entry;
      D_Entry : in out Directory_Entry;
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
            D_Entry.Long_Name_First := D_Entry.Long_Name'Last + 1;
            --  invalidate long name

            Last_Seq := 0;

         else
            if Last_Seq = 0
              or else Last_Seq - 1 /= V_Entry.VFAT_Attr.Sequence
            then
               D_Entry.Long_Name_First := D_Entry.Long_Name'Last + 1;
            end if;

            Last_Seq := V_Entry.VFAT_Attr.Sequence;

            Prepend (V_Entry.Name_3, D_Entry.Long_Name, D_Entry.Long_Name_First);
            Prepend (V_Entry.Name_2, D_Entry.Long_Name, D_Entry.Long_Name_First);
            Prepend (V_Entry.Name_1, D_Entry.Long_Name, D_Entry.Long_Name_First);

            if V_Entry.VFAT_Attr.Sequence = 1 then
               CRC := V_Entry.Checksum;
            end if;
         end if;
         --  VFAT needs more data...cannot return "OK", yet
      elsif not F_Entry.Attributes.Volume_Label --  Ignore Volumes
        and then Character'Pos (F_Entry.Filename (1)) /= 16#E5# --  Ignore deleted files
      then
         --  any other entry, which we return with "OK".
         if D_Entry.Long_Name_First not in D_Entry.Long_Name'Range then
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
            Short_Name : constant String :=
              Base &
            (if Ext'Length > 0
             then "." & Trim (F_Entry.Extension)
             else "");
         begin
            --  set short name
            D_Entry.Short_Name (1 .. Short_Name'Length) := Short_Name;
            D_Entry.Short_Name_Last := Short_Name'Length;
         end;

         D_Entry.Attributes    := F_Entry.Attributes;
         D_Entry.Start_Cluster := Unsigned_32 (F_Entry.Cluster_L);
         D_Entry.Size          := F_Entry.Size;
         D_Entry.FS            := FS;
         --  FIXME: add date and time

         if FS.Version = FAT32 then
            D_Entry.Start_Cluster :=
              D_Entry.Start_Cluster or
              Shift_Left (Unsigned_32 (F_Entry.Cluster_H), 16);
         end if;

         if not Matches then
            --  invalidate long name
            D_Entry.Long_Name_First := D_Entry.Long_Name'Last + 1;
         end if;

         return OK; -- finished fetching next entry
      end if;
      return Invalid_Name;
   end FAT_To_Directory_Entry;

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

      DEntry.Long_Name_First := DEntry.Long_Name'Last + 1; -- invalidate long name

      Fetch_Next : loop
         Block_Off :=
           Unsigned_16
             (Unsigned_32 (Dir.Current_Index) * ENTRY_SIZE
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
         F_Entry := To_Entry (Dir.FS.Window
                              (Block_Off .. Block_Off + ENTRY_SIZE - 1));
         Dir.Current_Index := Dir.Current_Index + 1;

         --  continue until we have an entry...because VFAT has multiple parts
         if FAT_To_Directory_Entry
           (Dir.FS, F_Entry, DEntry, Last_Seq) = OK
         then
            exit Fetch_Next;
         end if;
      end loop Fetch_Next;
      return OK;
   end Read;

   procedure Set_Shortname (newname : String; E : in out FAT_Directory_Entry) is
   begin
      if E.Attributes.Subdirectory then
         StrCpySpace (outstring => E.Filename, instring => newname);
         if newname'Length > E.Filename'Length then
            StrCpySpace (E.Extension, newname (newname'First + E.Filename'Length .. newname'Last));
         else
            StrCpySpace (E.Extension, "");
         end if;
      else
         --  file: remove '.' and limit to 8+3...
         declare
            base  : String (1 .. 8);
            ext   : String (1 .. 3);
            dotpos : constant Integer := StrChr (newname, '.');
         begin
            if dotpos in newname'Range then
               if dotpos = newname'First then
                  StrCpySpace (base, "");
               else
                  StrCpySpace (base, newname (newname'First .. dotpos - 1));
               end if;
               if dotpos = newname'Last then
                  StrCpySpace (ext, "");
               else
                  StrCpySpace (ext, newname (dotpos + 1 .. newname'Last));
               end if;
            else
               StrCpySpace (base, newname);
               StrCpySpace (ext, "");
            end if;
            E.Filename := base;
            E.Extension := ext;
         end;
      end if;
   end Set_Shortname;

   function Name (E : Directory_Entry) return String is
   begin
      if E.Long_Name_First in E.Long_Name'Range then
         return E.Long_Name (E.Long_Name_First .. E.Long_Name'Last);
      else
         return E.Short_Name (E.Short_Name'First .. E.Short_Name_Last);
      end if;
   end Name;

   function Allocate_Entry
     (Parent_Ent : Directory_Entry;
      New_Name   : String;
      Ent_Addr   : out FAT_Address) return Status_Code
   is
      Block_Off    : Unsigned_16;
      Parent       : Directory_Handle;
   begin
      if Parent_Ent.FS.Version /= FAT32 then
         --  we only support FAT32 for now.
         return Internal_Error;
      end if;

      --  skip to last entry, and make sure name doesn't exist
      if Open (Parent_Ent, Parent) /= OK then
         return Invalid_Object_Entry;
      end if;
      declare
         Ent : Directory_Entry;
      begin
         while Read (Parent, Ent) = OK loop
            declare
               ent_name : constant String := Name (Ent);
            begin
               --  FIXME: this isn't completely right, since ent_name
               --  went through FAT name compression, but New_Name not.
               if ent_name = New_Name then
                  return Already_Exists;
               end if;
            end;
         end loop;
      end;

      --  if we are here, then we reached the last entry in the directory.
      --  see whether block_off is small enough to accommodate another entry
      --  block_Off .. Block_Off + 31 must be available, otherwise we need a
      --  the next block
      --  Parent.Current_Index := Parent.Current_Index + 1;
      Block_Off := Unsigned_16 (Unsigned_32
                                (Parent.Current_Index) * ENTRY_SIZE
                                mod Parent.FS.Block_Size_In_Bytes);
      --  offset of entry within current block

      --  do we need a new block?
      if Block_Off = 0 and then Parent.Current_Index > 0 then
         --  need a new block
         Parent.Current_Block := Parent.Current_Block + 1;
         --  do we need to allocate a new cluster for the new block?
         if Parent.Current_Block -
           Parent.FS.Cluster_To_Block (Parent.Current_Cluster) =
           Unsigned_32 (Parent.FS.Number_Of_Blocks_Per_Cluster)
         then
            --  need another cluster. find free one and allocate it
            declare
               New_Cluster : Unsigned_32;
               Status : Status_Code;
            begin
               Status := Parent.FS.Append_Cluster
                 (Last_Cluster => Parent.Current_Cluster,
                  New_Cluster => New_Cluster);
               if Status /= OK then
                  return Status;
               end if;
               Parent.Current_Cluster := New_Cluster;
               Parent.Current_Block :=
                 Parent.FS.Cluster_To_Block (Parent.Current_Cluster);
            end;
         end if;
      end if;
      --  now write the new entry to the allocated space (Parent.current_clock + block_off)
      --  Ent_Addr.Cluster := Parent.Current_Cluster;
      Ent_Addr.Block_LBA := Parent.Current_Block;
      Ent_Addr.Block_Off := Block_Off;

      return OK;
   end Allocate_Entry;
end FAT_Filesystem.Directories;
