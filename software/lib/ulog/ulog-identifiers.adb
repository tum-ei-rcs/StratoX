--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
--
with Ada.Tags;

package body ULog.Identifiers is
   procedure Register (The_Tag : Ada.Tags.Tag; Code : Character) is
   begin
      null;
      --  TODO
   end Register;

   function Decode (Code : Character) return Ada.Tags.Tag is
   begin
      return Ada.Tags.No_Tag;
      --  TODO
   end Decode;

end ULog.Identifiers;
