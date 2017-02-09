with foo; use foo;
with Interfaces; use Interfaces;

--  GNATprove GPL 2016 seems to miss a failed precondition check
--  in the call at line 18. Reason is insufficient knowledge on
--  others=>, causing a false negative there, which in turn hides
--  a serious bug.
--  Fixed in GNATprove Pro 18 (and presumably later in GPL 2017)
procedure main with SPARK_Mode is

   --  inlined callee
   procedure bar (d : out Data_Type)
   is begin
      --pragma Assert (d'Length > 0);
      d := (others => 0); -- with this, GNATprove does not find violation in line 18
      pragma Annotate (GNATprove, False_Positive, "length check might fail", "insufficient solver knowledge");
      pragma Assert_And_Cut (d'Length >= 0);
      --d (d'First) := 0; -- with this, GNATprove indeed finds a violation in line 18
   end bar;

   arr : Data_Type (0 .. 91) := (others => 0);
   i32 : Integer_32;
begin
   bar (arr); -- essential
   i32 := foo.toInteger_32 (arr (60 .. 64)); -- length check proved, but actually exception
end main;
