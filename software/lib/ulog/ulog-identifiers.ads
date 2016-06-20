--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
--
with Ada.Tags;

--  @summary
--  implements a LUT/registration scheme to map ULOG messages
--  to unique numeric identifiers.
--
--  The only operations for Tags are ":=", "=" and whatever is
--  specified in Ada.Tags.
--
--  Inspired by Rationale for Ada 2005 §2.6
package ULog.Identifiers is
   procedure Register (The_Tag : Ada.Tags.Tag; Code : Character);

   function  Decode (Code : Character) return Ada.Tags.Tag;

end ULog.Identifiers;
