with MyStrings; use MyStrings;

package body Buildinfo with SPARK_Mode is

   function Short_Datetime return String is
      l_date : constant String := Compilation_ISO_Date;
      b_time : constant String := Strip_Non_Alphanum (Compilation_Time);
      b_date : constant String := Strip_Non_Alphanum (l_date (l_date'First + 2 .. l_date'Last));
      shortstring : String (1 .. 11);
   begin
      --  XXX array concatenation: L-value is should be a constrained array, see AARM-4.5.3-6f
      if b_date'Length > 5 and then b_time'Length > 3 then
         shortstring (1 .. 6) := b_date (b_date'First .. b_date'First + 5);
         pragma Annotate (GNATProve, False_Positive, """shortstring"" might not be initialized", "that is done right here");
         shortstring (7) := '_';
         shortstring (8 .. 11) := b_time (b_time'First .. b_time'First + 3);
      else
         declare
            tmp : String (1 .. 9);
         begin
            tmp (tmp'First .. tmp'First - 1 + b_date'Length) := b_date;
            pragma Annotate (GNATProve, False_Positive, """tmp"" might not be initialized", "that is done right here");
            tmp (tmp'First + b_date'Length) := '_';
            tmp (tmp'First + b_date'Length + 1 .. tmp'First + b_date'Length + b_time'Length) := b_time;
            StrCpySpace (instring => tmp, outstring => shortstring);
         end;
      end if;
      return shortstring;
   end Short_Datetime;

end Buildinfo;
