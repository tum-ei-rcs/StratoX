with Ada.Containers.Formal_Doubly_Linked_Lists;

package wrap with SPARK_Mode is

   type Element_Type is (ONE, TWO);
   function My_Eq (Left : Element_Type; Right : Element_Type) return Boolean is (Left = Right);

   package My_Lists is new Ada.Containers.Formal_Doubly_Linked_Lists (Element_Type, My_Eq);
   use My_Lists;

   li : My_Lists.List (10);

   procedure foo;

end wrap;
