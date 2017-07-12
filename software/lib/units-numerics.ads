--  Description: Wrapper to use Base_Unit_Type with a-nuelfu
--  TODO: all the postconditions are unproven, because a-nuelfu
--  builds on the generic C math interface
--  however, instead of modifying the RTS, we add them here and
--  leave them unproven (hoping the RTS introduces contracts later on)
package Units.Numerics with SPARK_Mode is
   
   function Sqrt (X : Base_Unit_Type) return Base_Unit_Type with 
     Pre => X >= 0.0,
     Contract_Cases => ((X >= 0.0 and then X < 1.0) => Sqrt'Result >= X,
                        (X >= 1.0) => Sqrt'Result <= X),
     Post => Sqrt'Result >= 0.0;
    
   
   function Log (X : Base_Unit_Type) return Base_Unit_Type with 
     Pre => X > 0.0,
     Contract_Cases => ((X <= 1.0) => Log'Result <= 0.0,
                        (X > 1.0)  => Log'Result >= 0.0),
     Post => Log'Result < X;   
   --  natural logarithm of <X>, R=>R+
   --  FIXME: very weak contract (magnitude of result could be approximated)
   
   
   function Exp (X : Base_Unit_Type) return Base_Unit_Type with 
     Pre => X <= Log (Base_Unit_Type'Last),       
     Post => Exp'Result >= 0.0; -- allow rounding
   --  return the base-e exponential function of <X>, i.e., e**X
   
   
   function "**" (Left : Base_Unit_Type; Right : Float) return Base_Unit_Type
     with Pre => Left > 0.0;
   -- FIXME: change implementation to allow negative base

   
   function Sin (X : Angle_Type) return Base_Unit_Type with
     Post => Sin'Result in -1.0 .. 1.0;   

   
   -- @req cosine-x
   function Cos (X : Angle_Type) return Base_Unit_Type with
     Post => Cos'Result in -1.0 .. 1.0;

         
   function Arctan
     (Y : Base_Unit_Type;
      X : Base_Unit_Type := 1.0) return Angle_Type with 
     Pre => X /= 0.0 or Y /= 0.0,
     Contract_Cases => ( Y >= 0.0 => Arctan'Result in    0.0 * Degree .. 180.0 * Degree,
                         Y <  0.0 => Arctan'Result in -180.0 * Degree .. 0.0 * Degree);
   --  Calculates angle to point y,x
   --  These postconditions are backed up by unit tests on the STM32F4 target.

   
   function Arctan
     (Y     : Base_Unit_Type'Base;
      X     : Base_Unit_Type'Base := 1.0;
      Cycle : Angle_Type) return Angle_Type with
     Post => Arctan'Result in -Cycle/2.0 .. Cycle/2.0;
   --  Calculates angle to point y,x, but wraps the result into the given cycle
         
   
--     function Arccot
--       (X : Base_Unit_Type;
--        Y : Base_Unit_Type := 1.0) return Angle_Type;
--              
--     function Arccot
--       (X     : Base_Unit_Type;
--        Y     : Base_Unit_Type := 1.0;
--        Cycle : Angle_Type) return Angle_Type;
--              
--     function Arcsin (X : Angle_Type) return Base_Unit_Type  
--       with Post => Arcsin'Result in -90.0*Degree .. 90.0*Degree;
--  
--     function Cos (X, Cycle : Angle_Type) return Base_Unit_Type;
--           
--     function Tan (X : Angle_Type) return Base_Unit_Type;
--           
--     function Tan (X, Cycle : Angle_Type) return Base_Unit_Type;
--           
--     function Cot (X : Angle_Type) return Base_Unit_Type;
--           
--     function Cot (X, Cycle : Angle_Type) return Base_Unit_Type;
--           
--     function Arcsin (X : Base_Unit_Type) return Angle_Type;
--           
--     function Arcsin (X : Base_Unit_Type; Cycle : Angle_Type) return Angle_Type;
--              
--     function Arccos (X  : Base_Unit_Type) return Angle_Type;
--           
--     function Arccos  (X : Base_Unit_Type; Cycle : Angle_Type) return Angle_Type;
--  
--     function Exp (X : Base_Unit_Type) return Float;
--     
--     function Log (X : Base_Unit_Type) return Float;
   
end Units.Numerics;
