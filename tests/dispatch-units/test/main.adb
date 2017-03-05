with Units; use Units;
with Ulog; use Ulog;
with Ulog.GPS; use Ulog.Gps;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Tags;
with Interfaces;

--  Rules for conversion in OO programming:
--  1. SPECIFIC TYPES: only up-cast (towards ancestors/base) possible
--    * view conversion, i.e., components not in parent are hidden
--    * tag stays untouched (really? then why no dispatching?)
--    * no initialization necessary
--    * not dispatching
--  2. CLASS-WIDE TYPES: both directions (ancestors <> descendant) possible
--    * view conversions
--    * requires initialization with specific
--    * dispatch works
--  3. VIEW RENAMING: to rename result of a view conversion
--    * view the result as target type
--    * optimal performance
--    * requires "initialization" with specific
--    * dispatch works
--  X. VIEW CONVERSION: if both source and target type are tagged, or
--    if appearing in a call as IN OUT or OUT paramete.
--  Y. VALUE CONVERSION: everything else
--  Z. DYAMIC DISPATCHING
--

procedure main is

   l : Length_Type;

begin

   consume (msg_gps);
   --  consume (msg);
   --  msg_gps.Describe;

end main;
