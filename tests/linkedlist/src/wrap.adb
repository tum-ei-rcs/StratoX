with Ada.Containers; use Ada.Containers;
with Ada.Text_IO; use Ada.Text_IO;

package body wrap with SPARK_Mode is
   procedure foo is
      c : My_Lists.Cursor;
   begin
      My_Lists.Clear (li);
      My_Lists.Append (li, One);
      c := My_Lists.First (li);
      Put_Line ("First=" & Element_Type'Image (My_Lists.Element (li, c)));
      c := My_Lists.Last (li);
      Put_Line ("Element1=" & Element_Type'Image (My_Lists.Element (li, c)));
      -- OK up to here

      if Has_Element (li, c) then
         c := My_Lists.Next(li, c); -- explicit raise, but pre is fine
         Put_Line ("Element2=" & Element_Type'Image (My_Lists.Element (li, c)));
      else
         Put_Line ("No second element");
      end if;


      c := My_Lists.Next(li, c); -- constraint error
      Put_Line ("Element3=" & Element_Type'Image (My_Lists.Element (li, c)));
   end foo;
end wrap;
