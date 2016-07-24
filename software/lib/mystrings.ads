--  Project: Strato
--  System:  Stratosphere Balloon Flight Controller
--  Author: Martin Becker (becker@rcs.ei.tum.de)

--  @summary String functions
package MyStrings is
   function Is_AlNum (c : Character) return Boolean;
   --  is the given character alphanumeric?

   function Strip_Non_Alphanum (s : String) return String;
   --  remove all non-alphanumeric characters from string

   function StrChr (S : String; C : Character) return Integer;
   --  search for occurence of character in string.
   --  return index in S, or S'Last + 1 if not found.

   procedure StrCpySpace (outstring : out String; instring : String);
   --  turn a string into a fixed-length string:
   --  if too short, pad with spaces until it reaches the given length
   --  if too long, then crop

   function Trim (S : String) return String;
   --  remove trailing spaces
end MyStrings;
