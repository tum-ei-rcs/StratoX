-- Project: Strato
-- System:  Stratosphere Balloon Flight Controller
-- Author: Martin Becker (becker@rcs.ei.tum.de)

-- @summary String functions
package body MyStrings is

   procedure StrCpySpace (outstring : out String; instring : String) is
   begin
      if instring'Length >= outstring'Length then
         -- trim
         outstring := instring (instring'First .. instring'First + outstring'Length - 1);
      else
         -- pad
         outstring (1 .. instring'Length) := instring;
         outstring (instring'Length + 1 .. outstring'Length) := (others => ' ');
      end if;
   end StrCpySpace;

   function Trim (S : String) return String
   is
   begin
      for J in reverse S'Range loop
         if S (J) /= ' ' then
            return S (S'First .. J);
         end if;
      end loop;

      return "";
   end Trim;

   function StrChr (S : String; C : Character) return Integer is
   begin
      for idx in S'Range loop
         if S (idx) = C then
            return idx;
         end if;
      end loop;
      return S'Last + 1;
   end StrChr;

   function Is_AlNum (c : Character) return Boolean is
   begin
      return (c in 'a'..'z') or (c in 'A'..'Z') or (c in '0'..'9');
   end Is_AlNum;

   function Strip_Non_Alphanum (s : String) return String is
      tmp : String (1 .. s'Length) := s;
      len : Integer := 0;
   begin
      for c in s'Range loop
         if Is_AlNum (s (c)) then
            len := len + 1;
            tmp (len) := s (c);
         end if;
      end loop;
      declare
         ret : constant String (1 .. len) := tmp (1 .. len);
      begin
         return ret;
      end;
   end Strip_Non_Alphanum;

end MyStrings;
