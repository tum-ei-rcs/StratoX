-- Generic Buffer
-- Author: Emanuel Regnath (emanuel.regnath@tum.de)
-- Can be used as ring buffer or queue

generic
   type Index_Type is mod <>;
   type Element_Type is private;
package Generic_Queue with SPARK_Mode is

   subtype Length_Type is Natural range 0 .. Integer( Index_Type'Last ) + 1;
   type Element_Array is array (Length_Type range <>) of Element_Type;

   type Mode_Type is (RING, QUEUE);

   type Buffer_Element_Array is private;

   protected type Buffer_Type is

      procedure clear with post => Empty;
      -- remove all elements

      procedure push_back( element : Element_Type ) with post => not Empty;
      -- append new element at back

      procedure push_front( element : Element_Type ) with post => not Empty;
      -- prepend new element at front

      procedure pop_front( element : out Element_Type ) with pre => not Empty, post => not Full;
      -- read and remove element at front

      entry pop_front_blocking( element : out Element_Type );
      -- wait until buffer is not empty then read and remove element at front

      procedure pop_back( element : out Element_Type) with pre => not Empty, post => not Full;
      -- read and remove element at back

      procedure pop_all( elements : out Element_Array )
         with post => Empty;
         -- read and remove all elements, front first

      procedure get_front( element : out Element_Type ) with pre => not Empty;
      -- read element at front

      procedure get_back( element : out Element_Type ) with pre => not Empty;
      -- read element at back

      procedure get_all( elements : out Element_Array ) with pre => elements'Length = Length;
      -- read all elements, front first

      --function get_at( index : Index_Type ) return Element_Type;

      function get_nth_first( nth : Index_Type ) return Element_Type;
      -- read nth element, nth = 0 is front

      function get_nth_last( nth : Index_Type ) return Element_Type;
      -- read nth element, nth = 0 is back

      function Length return Length_Type;
      -- number of elements in buffer

      function Empty return Boolean;
      -- true if buffer is empty

      function Full return Boolean;
      -- true if buffer is full

      function Overflows return Natural;
      -- number of buffer overflows

   private
      mode        : Mode_Type := RING;
      buffer      : Buffer_Element_Array;
      index_head  : Index_Type := 0;
      index_tail  : Index_Type := 0;
      hasElements : Boolean := False;
      Num_Overflows : Natural := 0;

      procedure p_get_all( elements : out Element_Array );

   end Buffer_Type;

private
   type Buffer_Element_Array is array (Index_Type) of Element_Type;


end Generic_Queue;
