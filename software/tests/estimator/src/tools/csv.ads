with Ada.Text_IO;

package CSV is


   type Row(<>) is tagged private;

   function Get_Row ( f : Ada.Text_IO.File_Type; filesep : Character) return Row;
   function Next(R: in out Row) return Boolean;
     -- if there is still an item in R, Next advances to it and returns True
   function Item(R: Row) return String;
     -- after calling R.Next i times, this returns the i'th item (if any)

   function Parse_Line(S : String; filesep: Character) return Row;
private
   type Row(Length: Natural) is tagged record
      Str: String(1 .. Length);
      Fst: Positive;
      Lst: Natural;
      Nxt: Positive;
      Sep: Character;
   end record;

end CSV;
