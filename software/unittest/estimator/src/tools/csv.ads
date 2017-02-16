with Ada.Text_IO;

generic
   filename : String;
   filesep : Character := ';';
package CSV is

   function Open return Boolean;
   -- open the file

   procedure Parse_Header;
   -- read next line and treat it as header labels


   function Parse_Row return Boolean;
   -- read next line and assign values to labels

   function Get_Column (name : String) return Float;
   -- get value for label

   procedure Dump_Columns;
   -- print all column data of current row

   function End_Of_File return Boolean;

   procedure Close;
   -- close the file

private

   type Row(Length: Natural) is tagged record
      Str: String(1 .. Length);
      Fst: Positive;
      Lst: Natural;
      Nxt: Positive;
      Sep: Character;
   end record;

   function Parse_Line(S : String; filesep: Character) return Row;

   function Next(R: in out Row) return Boolean;
     -- if there is still an item in R, Next advances to it and returns True
   function Item(R: Row) return String;
   -- after calling R.Next i times, this returns the i'th item (if any)

   file : Ada.Text_IO.File_Type;
end CSV;
