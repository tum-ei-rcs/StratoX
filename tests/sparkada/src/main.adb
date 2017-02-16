procedure main is

   function foo (x : integer) return integer with
     Pre => x < Integer'Last
   is
   begin
      return x+1;
   end foo;
   pragma Precondition (x < Integer'Last);

   x, y: integer;
begin
   x:= Integer'Last;
   y := foo(x);
end main;
