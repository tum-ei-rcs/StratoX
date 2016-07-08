

generic
   type Index_Type is mod <>;
   type Element_Type is private;
package Generic_Queue is

   -- type Index_Type is mod Length;
   type Element_Array is array (Natural range <>) of Element_Type;
   type Constrained_Element_Array is array (Index_Type) of Element_Type;
   subtype Length_Type is Natural range 0 .. Integer( Index_Type'Last );

   type Mode_Type is (RING, QUEUE);

   protected type Ring_Buffer_Type is

      procedure clear;

      procedure push_back( item : Element_Type);
      procedure push_front( item : Element_Type );
      procedure pop_front( item : out Element_Type);

      procedure get_Buffer( buf : out Element_Array );

      function get_front return Element_Type;
      function get_back return Element_Type;

      function get_at( index : Index_Type ) return Element_Type;
      function get_nth_newest( nth : Index_Type ) return Element_Type;
      function get_nth_oldest( nth : Index_Type ) return Element_Type;

      function Length return Length_Type;
      function Empty return Boolean;
      function Full return Boolean;


   private
      mode       : Mode_Type := RING;
      buffer     : Constrained_Element_Array;
      index_head : Index_Type := 0;
      index_tail : Index_Type := 0;
      isEmpty    : Boolean := True;
      Num_Overflows : Natural := 0;

   end Ring_Buffer_Type;

   --subtype Buffer_Type is Ring_Buffer_Type;
end Generic_Queue;
