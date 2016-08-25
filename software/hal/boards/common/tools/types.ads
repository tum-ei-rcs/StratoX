--  Institution: Technische Universitaet Muenchen
--  Department: Realtime Computer Systems (RCS)
--  Project: StratoX
--  Module: Types
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--          Martin Becker (becker@rcs.ei.tum.de)
--
--  @summary: Common used type definitions and functions
package Types with SPARK_Mode is


   generic
      type T is range <>; -- for signed integers
   function Saturated_Cast_Int (f : Float) return T;
   --  cast a float into any discrete type
   
   generic
      type T is mod <>; -- for modular types
   function Saturated_Cast_Mod (f : Float) return T;
   

end Types;
