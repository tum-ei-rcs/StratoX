package Buildinfo with SPARK_Mode is

   function Compilation_ISO_Date return String -- implementation-defined (GNAT)
     with Import, Convention => Intrinsic,
     Global => null,
     Post => Compilation_ISO_Date'Result'Length = 10;
   --  returns "YYYY-MM-DD"

   function Compilation_Time return String -- implementation-defined (GNAT)
     with Import, Convention => Intrinsic,
     Global => null,
     Post => Compilation_Time'Result'Length in 7 .. 8;
   --  returns "HH:MM:SS"

   function Short_Datetime return String
     with Post => Short_Datetime'Result'Length = 11;
   --  returns "YYMMDD_HHMM"

end Buildinfo;
