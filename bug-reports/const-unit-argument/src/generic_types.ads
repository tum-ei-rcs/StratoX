--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Module:      Generic Types
--
--  Authors:  Martin Becker (becker@rcs.ei.tum.de)
--
--  @summary: Commonly used functions on basic types
package Generic_Types with SPARK_Mode is


   generic
      type T is range <>; -- for signed integers
   function Saturated_Cast_Int (f : Float) return T;
   --  cast a float into any discrete type
   
   generic
      type T is mod <>; -- for modular types
   function Saturated_Cast_Mod (f : Float) return T;
   
   generic
      type T is mod <>; -- for modular types
   function Saturate_Mod (val : T; min : T; max : T) return T
     with Post => Saturate_Mod'Result in min .. max;

end Generic_Types;
