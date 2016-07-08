

package body Generic_Queue is

--  Buffer Structure:
--  | 0:X | 1:– | 2:– | 3:– |
--    ^h    ^t
--   head(h) points to oldest, tail(t) to next free,
--   empty: t=h, full: t+1=h


   protected body Ring_Buffer_Type is

      procedure clear is
      begin
         index_head := Index_Type'First;
         index_tail := Index_Type'First;
         isEmpty := True;
      end clear;


      procedure push_back( item : Element_Type) is
      begin
         if Full then -- overflow
            index_head := Index_Type'Succ( index_head );
            if Num_Overflows < Natural'Last then
               Num_Overflows := Num_Overflows + 1;
            end if;
         end if;
         Buffer(index_tail) := item;
         index_tail := Index_Type'Succ( index_tail );

         pragma Assert ( not Empty );
      end push_back;


      procedure push_front( item : Element_Type ) is
      begin
          if Full then -- overflow
            index_tail := Index_Type'Pred( index_tail );
            if Num_Overflows < Natural'Last then
               Num_Overflows := Num_Overflows + 1;
            end if;
         end if;
         index_head := Index_Type'Succ( index_tail );
         Buffer(index_head) := item;


         pragma Assert ( not Empty );
      end push_front;


      procedure pop_front( item : out Element_Type) is
      begin
         if (not Empty) then
            item := Buffer(index_head);
            index_head := Index_Type'Succ( index_head );
         end if;
         if index_tail = index_head then
            isEmpty := True;
         end if;
      end pop_front;


      procedure get_Buffer( buf : out Element_Array ) is
         -- buf : Element_Array(index_head .. index_tail-1);
      begin
         if not Empty then
            if index_head <= index_tail-1 then  -- no wrap
               buf(0 .. Length-1) := Element_Array( Buffer(index_head .. index_tail-1) );
            else
               buf(0 .. Length-1) := Element_Array( Buffer(index_head .. Index_Type'Last) & Buffer(Index_Type'First .. index_tail-1) );
            end if;
         else
            buf := Element_Array( Buffer(1 .. 0) ); -- empty
         end if;
      end get_Buffer;


      function get_front return Element_Type is
      begin
         pragma Assert (not Empty);
         return buffer( index_head );
      end get_front;

      function get_back return Element_Type is
      begin
         pragma Assert (not Empty);
         return buffer( index_tail - 1 );
      end get_back;

      function get_at( index : Index_Type ) return Element_Type is
      begin
         pragma Assert ( index_head <= index and index < index_tail );
         return buffer( index );
      end get_at;

      function get_nth_newest( nth : Index_Type ) return Element_Type is
      begin
         pragma Assert ( index_head <= index_tail-1 - nth );
         return buffer( index_tail-1 - nth );
      end get_nth_newest;

      function get_nth_oldest( nth : Index_Type ) return Element_Type is
      begin
         pragma Assert ( index_head + nth <= index_tail-1 );
         return buffer( index_head + nth );
      end get_nth_oldest;

      function Length return Length_Type is
      begin
         if Full then
            return Length_Type'Last;
         else
            return Length_Type(index_tail - index_head);
         end if;
      end Length;

      function Full return Boolean is
      begin
          return (index_tail = index_head) and not Empty;
      end Full;

      function Empty return Boolean is
      begin
         return isEmpty; -- (index_tail = index_head);
      end Empty;

   end Ring_Buffer_Type;

end Generic_Queue;
