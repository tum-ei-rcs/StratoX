package wrap is

   with Ada.Containers.Formal_Doubly_Linked_Lists;

   package My_Lists is new Ada.Containers.Formal_Doubly_Linked_Lists (Element_Type, My_Eq);
end wrap;
