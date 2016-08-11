with Interfaces; use Interfaces;

procedure main with SPARK_Mode is
   type Some_Record is
       record
          c1 : Unsigned_8 := 0;
          c2 : Unsigned_8 := 0;
       end record;
   for Some_Record'Size use 16;
   foo : Some_Record;

   off_c1 : constant Integer := foo.c1'Position; -- [Transform_Attr] not implemented: ATTRIBUTE_POSITION
begin
   null;
end main;
