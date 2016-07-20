with Ada.Text_IO;
use Ada.Text_IO;
with Ada.Containers.Ordered_Maps;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body CSV is

   package Associative_Str is new Ada.Containers.Ordered_Maps(Integer, Unbounded_String);
   package Associative_Data is new Ada.Containers.Ordered_Maps(Unbounded_String, Float);
   use Associative_Data;
   Col_Map  : Associative_Str.Map; -- maps column number to column name
   Data_Map : Associative_Data.Map; -- maps column name to current data

   function Parse_Line(S: String; filesep: Character)
                return Row is
      (Length => S'Length, Str => S,
       Fst => S'First, Lst => S'Last, Nxt => S'First, Sep => filesep);

   function End_Of_File return Boolean is
   begin
      return Ada.Text_IO.End_Of_File (file);
   end End_Of_File;

   procedure Dump_Columns is
     Index : Associative_Data.Cursor := Data_Map.First;
   begin
      while Index /= Associative_Data.No_Element loop
         Put (To_String (Key (Index)) & "=" & Float'Image (Element (Index)));
         Index := Next (Index);
         if Index /= Associative_Data.No_Element then
            Put (", ");
         end if;
      end loop;
      New_Line;
   end;

   function Get_Column (name : String) return Float is
      colname : Unbounded_String :=  To_Unbounded_String (name);
   begin
      if not Data_Map.Contains (colname) then
         Put_Line ("ERROR: no column '" & name & "' in file " & filename);
         return 0.0;
      else
         return Data_Map.Element (colname);
      end if;
   end Get_Column;

   function Parse_Row return Boolean is
      Line : constant String := Get_Line (file);
      r : Row := Parse_Line (Line, filesep);
      k : Positive := 1;
   begin
      while r.Next loop
         declare
            colname : Unbounded_String := Col_Map.Element (k); -- get column name by index
            Data_Cursor : Associative_Data.Cursor;
            succ : Boolean;
            value : Float;
         begin
            value := Float'Value (r.Item);
            if not Data_Map.Contains (colname) then
               Data_Map.Insert (colname, value, Data_Cursor, succ);
            else
               Data_Map.Replace (colname, value);
            end if;
            --Put_Line ("CSV Parse: col=" & Ada.Strings.Unbounded.To_String (colname) & ", val=" & value'img);
         end;
         k := k + 1;
      end loop;
      return True;
   end Parse_Row;

   procedure Parse_Header is
      Line : String := Get_Line (file);
      head : Row := Parse_Line (Line, filesep);
      k : Positive := 1;
      Col_Cursor_Rev : Associative_Str.Cursor;
      Success : Boolean;
   begin
      --  Put ("Header: ");
      while head.Next loop
         Col_Map.Insert (k,To_Unbounded_String (head.Item), Col_Cursor_Rev, Success);
         --  Put (k'img & " => " & head.Item & ",");
         k := k + 1;
      end loop;
      --New_Line;
   end Parse_Header;

   function Item(R: Row) return String is
      (R.Str(R.Fst .. R.Lst));

   procedure Close is
   begin
      Ada.Text_IO.Close (file);
   end Close;

   function Next(R : in out Row) return Boolean is
      Last: Natural := R.Nxt;
   begin
      R.Fst := R.Nxt;
      while Last <= R.Str'Last and then R.Str(Last) /= R.Sep loop
         -- find Separator
         Last := Last + 1;
      end loop;
      R.Lst := Last - 1;
      R.Nxt := Last + 1;
      return (R.Fst <= R.Str'Last);
   end Next;

   function Open return Boolean is
   begin
      Ada.Text_IO.Open (File => file,
                        Mode => Ada.Text_IO.In_File,
                        Name => filename);
      return Ada.Text_IO.Is_Open (file);
   end Open;

end CSV;
