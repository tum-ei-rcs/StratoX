

package body Generic_Queue with SPARK_Mode is

   --  Buffer Structure:
   --  | 0:X | 1:– | 2:– | 3:– |
   --    ^h    ^t
   --   head(h) points to oldest, tail(t) to next free,
   --   empty: t=h, full: t=h  => Flag Self.hasElements required


   ---------------
   -- copy_array
   ---------------
   procedure copy_array (Self : in Buffer_Tag; elements : out Element_Array) with
     Pre'Class => Self.Length >= elements'Length,
     Post'Class => Self.Length = Self.Length'Old,
       Global => null;
   --  copies n front elements from Self to elements, where n=elements'length

   procedure copy_array (Self : in Buffer_Tag; elements : out Element_Array) is
      pos : Index_Type := Self.index_head;
   begin
      for e in elements'Range loop
         elements (e) := Self.Buffer (pos);
         pos := pos + 1; -- mod type. Does the right thing.
      end loop;
   end copy_array;

   -----------
   -- Length
   -----------
   function Length( Self : in Buffer_Tag ) return Length_Type is
   begin
      if Self.Full then
         return Length_Type'Last;
      else
         return Length_Type( Index_Type(Self.index_tail - Self.index_head) );
      end if;
   end Length;

   --------
   -- Full
   --------
   function Full( Self : in Buffer_Tag ) return Boolean is ((Self.index_tail = Self.index_head) and Self.hasElements);

   ---------
   -- Empty
   ---------
   function Empty( Self : in Buffer_Tag ) return Boolean is (not Self.hasElements);

   ----------
   -- clear
   ----------
   procedure clear( Self : in out Buffer_Tag ) is
   begin
      Self.index_head := Index_Type'First;
      Self.index_tail := Index_Type'First;
      Self.hasElements := False;
   end clear;

   ----------
   -- fill
   ----------
--     procedure fill( Self : in out Buffer_Tag ) is
--     begin
--        Self.index_tail := Self.index_head;
--        Self.hasElements := True;
--     end fill;

   -------------
   -- push_back
   -------------
   procedure push_back( Self : in out Buffer_Tag; element : Element_Type) is
   begin
      if Self.Full then -- overflow
         Self.index_head := Index_Type'Succ( Self.index_head );
         if Self.Num_Overflows < Natural'Last then
            Self.Num_Overflows := Self.Num_Overflows + 1;
         end if;
      end if;
      Self.Buffer( Self.index_tail) := element;
      Self.index_tail := Index_Type'Succ( Self.index_tail );
      Self.hasElements := True;
   end push_back;

   --------------
   -- push_front
   --------------
   procedure push_front( Self : in out Buffer_Tag; element : Element_Type ) is
   begin
      if Self.Full then -- overflow
         Self.index_tail := Index_Type'Pred( Self.index_tail );
         if Self.Num_Overflows < Natural'Last then
            Self.Num_Overflows := Self.Num_Overflows + 1;
         end if;
      end if;
      Self.index_head := Index_Type'Pred( Self.index_head );
      Self.Buffer( Self.index_head) := element;
      Self.hasElements := True;

   end push_front;

   -------------
   -- pop_front
   -------------
   procedure pop_front( Self : in out Buffer_Tag; element : out Element_Type) is
   begin
      element := Self.Buffer( Self.index_head);
      Self.index_head := Index_Type'Succ( Self.index_head );
      if Self.index_tail = Self.index_head then
         Self.hasElements := False;
      end if;
   end pop_front;

   procedure pop_front( Self : in out Buffer_Tag; elements : out Element_Array ) is
   begin
      copy_array (Self, elements);
      Self.index_head := Self.index_head + Index_Type'Mod (elements'Length);
      if Self.index_tail = Self.index_head then
         Self.hasElements := False;
      end if;
   end pop_front;

   --        entry pop_front_blocking( Self : in out Buffer_Tag; element : out Element_Type ) when Self.hasElements is
   --        begin
   --           element := Self.Buffer( Self.index_head);
   --           Self.index_head := Index_Type'Succ( Self.index_head );
   --           if Self.index_tail = Self.index_head then
   --              Self.hasElements := False;
   --           end if;
   --        end pop_front_blocking;

   ------------
   -- pop_back
   ------------
   procedure pop_back( Self : in out Buffer_Tag; element : out Element_Type) is
   begin
      Self.index_tail := Index_Type'Pred( Self.index_tail );
      element := Self.Buffer( Self.index_tail);
      if Self.index_tail = Self.index_head then
         Self.hasElements := False;
      end if;
   end pop_back;

   -----------
   -- pop_all
   -----------
   procedure pop_all( Self : in out Buffer_Tag; elements : out Element_Array ) is
   begin
      copy_array (Self, elements);
      Self.index_tail := 0;
      Self.index_head := 0;
      Self.hasElements := False;
   end pop_all;

   -----------
   -- get_all
   -----------
   procedure get_all( Self : in Buffer_Tag; elements : out Element_Array ) is
   begin
      copy_array (Self, elements);
   end get_all;

   -------------
   -- get_front
   -------------
   procedure get_front( Self : in Buffer_Tag; element : out Element_Type ) is
   begin
      element := Self.Buffer(  Self.index_head );
   end get_front;

   procedure get_front( Self : in Buffer_Tag; elements : out Element_Array ) is
   begin
      copy_array (Self, elements);
   end get_front;

   -------------
   -- get_back
   -------------
   procedure get_back( Self : in Buffer_Tag; element : out Element_Type ) is
   begin
      element := Self.Buffer(  Self.index_tail - 1 );
   end get_back;

   -- FIXME: remove this function?
--     function get_at( Self : in out Buffer_Tag; index : Index_Type ) return Element_Type is
--     begin
--        pragma Assert ( Self.index_head <= index and index < Self.index_tail );
--        return Self.Buffer(  index );
--     end get_at;

   -----------------
   -- get_nth_first
   -----------------
   procedure get_nth_first( Self : in Buffer_Tag; nth : Index_Type; element : out Element_Type) is
   begin
      pragma Assert ( Self.index_head <= Self.index_tail-1 - nth );
      element := Self.Buffer(  Self.index_tail-1 - nth );
   end get_nth_first;

   ----------------
   -- get_nth_last
   ----------------
   procedure get_nth_last( Self : in Buffer_Tag; nth : Index_Type; element : out Element_Type) is
   begin
      pragma Assert ( Self.index_head + nth <= Self.index_tail-1 );
      element := Self.Buffer(  Self.index_head + nth );
   end get_nth_last;


   function Overflows( Self : in Buffer_Tag ) return Natural is
   begin
      return Self.Num_Overflows;
   end Overflows;

end Generic_Queue;
