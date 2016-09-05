--  Institution: Technische Universitaet Muenchen
--  Department: Realtime Computer Systems (RCS)
--  Project: StratoX
--  Module: Types
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--          Martin Becker (becker@rcs.ei.tum.de)
with Interfaces;    use Interfaces;
with Generic_Types; use Generic_Types;

--  @summary: Common used type definitions and functions
package Types with SPARK_Mode is
   
   function Limit_Unsigned16 is new Saturate_Mod (Unsigned_16);
   
   function Sat_Cast_Natural is new Saturated_Cast_Int (Natural);
   function Sat_Cast_Int is new Saturated_Cast_Int (Integer);
   function Sat_Cast_Int8 is new Saturated_Cast_Int (Integer_8);
   function Sat_Cast_U16 is new Saturated_Cast_Mod (Unsigned_16);
end Types;
