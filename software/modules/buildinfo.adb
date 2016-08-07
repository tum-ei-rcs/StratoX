with MyStrings; use MyStrings;

package body Buildinfo with SPARK_Mode is

   function Short_Datetime return String is
      b_time : constant String := Strip_Non_Alphanum (Compilation_Time);
      b_date : constant String := Strip_Non_Alphanum (Compilation_Date);
      shortstring : String (1 .. 11);
   begin
      if b_date'Length > 5 and then b_time'Length > 3 then
         shortstring := b_date (1 .. 6) & '_' & b_time (1 .. 4);
      else
         StrCpySpace (instring => b_date & "_" & b_time, outstring => shortstring);
      end if;
      return shortstring;
   end Short_Datetime;

end Buildinfo;
