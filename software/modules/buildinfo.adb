with MyStrings; use MyStrings;

package body Buildinfo with SPARK_Mode is

   function Short_Datetime return String is
      l_date : constant String := Compilation_ISO_Date;
      b_time : constant String := Strip_Non_Alphanum (Compilation_Time);
      b_date : constant String := Strip_Non_Alphanum (l_date (l_date'First + 2 .. l_date'Last));
      shortstring : String (1 .. 11);
   begin
      if b_date'Length > 5 and then b_time'Length > 3 then
         shortstring := b_date (b_date'First .. b_date'First + 5) & '_'
           & b_time (b_time'First .. b_time'First + 3);
      else
         StrCpySpace (instring => b_date & "_" & b_time, outstring => shortstring);
      end if;
      return shortstring;
   end Short_Datetime;

end Buildinfo;
