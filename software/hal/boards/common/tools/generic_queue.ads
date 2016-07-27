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

   type Buffer_Tag is tagged private;

      procedure clear( Self : in out Buffer_Tag ) with post => Self.Empty;
      -- remove all elements

      procedure fill( Self : in out Buffer_Tag );

      procedure push_back( Self : in out Buffer_Tag; element : Element_Type ) with post => not Self.Empty;
      -- append new element at back

      procedure push_front( Self : in out Buffer_Tag; element : Element_Type ) with post => not Self.Empty;
      -- prepend new element at front

      procedure pop_front( Self : in out Buffer_Tag; element : out Element_Type ) with pre => not Self.Empty, post => not Self.Full;
      -- read and remove element at front

      procedure pop_front( Self : in out Buffer_Tag; elements : out Element_Array ) with pre => elements'Length <= Self.Length;

      -- entry pop_front_blocking( Self : in out Buffer_Tag; element : out Element_Type );
      -- wait until buffer is not empty then read and remove element at front

      procedure pop_back( Self : in out Buffer_Tag; element : out Element_Type) with pre => not Self.Empty, post => not Self.Full;
      -- read and remove element at back

      procedure pop_all( Self : in out Buffer_Tag; elements : out Element_Array )
         with post => Self.Empty;
         -- read and remove all elements, front first

      procedure get_front( Self : in out Buffer_Tag; element : out Element_Type ) with pre => not Self.Empty;
      -- read element at front

      procedure get_front( Self : in out Buffer_Tag; elements : out Element_Array ) with pre => elements'Length <= Self.Length;
      -- read element at front

      procedure get_back( Self : in out Buffer_Tag; element : out Element_Type ) with pre => not Self.Empty;
      -- read element at back

      procedure get_all( Self : in out Buffer_Tag; elements : out Element_Array ) with pre => elements'Length = Self.Length;
      -- read all elements, front first

      --function get_at( index : Index_Type ) return Element_Type;

      function get_nth_first( Self : in out Buffer_Tag; nth : Index_Type ) return Element_Type;
      -- read nth element, nth = 0 is front

      function get_nth_last( Self : in out Buffer_Tag; nth : Index_Type ) return Element_Type;
      -- read nth element, nth = 0 is back

      function Length( Self : in Buffer_Tag) return Length_Type;
      -- number of elements in buffer

      function Empty( Self : in Buffer_Tag) return Boolean;
      -- true if buffer is empty

      function hasElements( Self : in Buffer_Tag) return Boolean;
      -- true if buffer has elements

      function Full( Self : in Buffer_Tag) return Boolean;
      -- true if buffer is full

      function Overflows( Self : in Buffer_Tag) return Natural;
      -- number of buffer overflows



private
   type Buffer_Element_Array is array (Index_Type) of Element_Type;

   type Buffer_Tag is tagged record
      mode        : Mode_Type := RING;
      buffer      : Buffer_Element_Array;
      index_head  : Index_Type := 0;
      index_tail  : Index_Type := 0;
      hasElements : Boolean := False;
      Num_Overflows : Natural := 0;
   end record;

   procedure p_get_all( Self : in out Buffer_Tag; elements : out Element_Array );
   procedure p_get( Self : in out Buffer_Tag; elements : out Element_Array );

end Generic_Queue;
