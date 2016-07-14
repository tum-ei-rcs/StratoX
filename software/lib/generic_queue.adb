

package body Generic_Queue with SPARK_Mode is

--  Buffer Structure:
--  | 0:X | 1:– | 2:– | 3:– |
--    ^h    ^t
--   head(h) points to oldest, tail(t) to next free,
--   empty: t=h, full: t=h  => Flag hasElements required


   protected body Buffer_Type is

      procedure clear is
      begin
         index_head := Index_Type'First;
         index_tail := Index_Type'First;
         hasElements := False;
      end clear;


      procedure push_back( element : Element_Type) is
      begin
         if Full then -- overflow
            index_head := Index_Type'Succ( index_head );
            if Num_Overflows < Natural'Last then
               Num_Overflows := Num_Overflows + 1;
            end if;
         end if;
         Buffer(index_tail) := element;
         index_tail := Index_Type'Succ( index_tail );
         hasElements := True;

         pragma Assert ( not Empty );
      end push_back;


      procedure push_front( element : Element_Type ) is
      begin
         if Full then -- overflow
            index_tail := Index_Type'Pred( index_tail );
            if Num_Overflows < Natural'Last then
               Num_Overflows := Num_Overflows + 1;
            end if;
         end if;
         index_head := Index_Type'Pred( index_head );
         Buffer(index_head) := element;
         hasElements := True;

         pragma Assert ( not Empty );
      end push_front;


      procedure pop_front( element : out Element_Type) is
      begin
         pragma Assert (not Empty);

         element := Buffer(index_head);
         index_head := Index_Type'Succ( index_head );
         if index_tail = index_head then
            hasElements := False;
         end if;
      end pop_front;

      entry pop_front_blocking( element : out Element_Type ) when hasElements is
      begin
         element := Buffer(index_head);
         index_head := Index_Type'Succ( index_head );
         if index_tail = index_head then
            hasElements := False;
         end if;
      end pop_front_blocking;

      procedure pop_back( element : out Element_Type) is
      begin
         pragma Assert (not Empty);

         index_tail := Index_Type'Pred( index_tail );
         element := Buffer(index_tail);
         if index_tail = index_head then
            hasElements := False;
         end if;
      end pop_back;

      procedure pop_all( elements : out Element_Array ) is
      begin
         p_get_all( elements );
         index_tail := 0;
         index_head := 0;
         hasElements := False;
      end pop_all;

      procedure get_all( elements : out Element_Array ) is
      begin
         p_get_all( elements );
      end get_all;

      procedure get_front( element : out Element_Type ) is
      begin
         pragma Assert (not Empty);
         element := buffer( index_head );
      end get_front;

      procedure get_back( element : out Element_Type ) is
      begin
         pragma Assert (not Empty);
         element := buffer( index_tail - 1 );
      end get_back;

      -- FIXME: remove this function?
      function get_at( index : Index_Type ) return Element_Type is
      begin
         pragma Assert ( index_head <= index and index < index_tail );
         return buffer( index );
      end get_at;

      function get_nth_first( nth : Index_Type ) return Element_Type is
      begin
         pragma Assert ( index_head <= index_tail-1 - nth );
         return buffer( index_tail-1 - nth );
      end get_nth_first;

      function get_nth_last( nth : Index_Type ) return Element_Type is
      begin
         pragma Assert ( index_head + nth <= index_tail-1 );
         return buffer( index_head + nth );
      end get_nth_last;

      function Length return Length_Type is
      begin
         if Full then
            return Length_Type'Last;
         else
            return Length_Type( Index_Type(index_tail - index_head) );
         end if;
      end Length;

      function Full return Boolean is
      begin
          return (index_tail = index_head) and hasElements;
      end Full;

      function Empty return Boolean is
      begin
         return not hasElements;
      end Empty;

      function Overflows return Natural is
      begin
         return Num_Overflows;
      end Overflows;


      procedure p_get_all( elements : out Element_Array ) is
      begin
         if not Empty then
            if index_head <= index_tail-1 then  -- no wrap
               elements(1 .. Length) := Element_Array( Buffer(index_head .. index_tail-1) );
            else
               elements(1 .. Length) := Element_Array( Buffer(index_head .. Index_Type'Last) & Buffer(Index_Type'First .. index_tail-1) );
            end if;
         else
            elements(1 .. 0) := Element_Array( Buffer(1 .. 0) ); -- empty
         end if;
      end p_get_all;


   end Buffer_Type;

end Generic_Queue;
