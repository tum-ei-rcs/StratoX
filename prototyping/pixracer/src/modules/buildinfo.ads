package Buildinfo is
   function Compilation_Date return String -- implementation-defined (GNAT)
     with Import, Convention => Intrinsic;
   function Compilation_Time return String -- implementation-defined (GNAT)
     with Import, Convention => Intrinsic;

   function Short_Datetime return String;
end Buildinfo;
