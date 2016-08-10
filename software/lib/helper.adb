with Ada.Real_Time; use Ada.Real_Time;

package body Helper with SPARK_Mode is


   function addWrap(x   : Numeric_Type;
                    inc : Numeric_Type) return Numeric_Type
   is
   begin
      if x + inc > Numeric_Type'Last then
         return x + inc - Numeric_Type'Last;
      else
         return x + inc;
      end if;
   end addWrap;


   procedure delay_ms( ms : Natural) is
      current_time : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      delay until current_time + Ada.Real_Time.Milliseconds( ms );
   end delay_ms;

   subtype Balance_Type is Float range -1.0 .. 1.0;
   pragma Unreferenced (Balance_Type);

   --function mix( channel_a : Float; channel_b : Float; balance : Balance_Type);

end Helper;
