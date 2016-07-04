



package Units.Numerics with SPARK_Mode is

   function Sqrt (X : Unit_Type) return Float;
   function "**" (Left : Unit_Type; Right : Integer) return Float;
   function "**" (Left : Unit_Type; Right : Float) return Unit_Type;

--   function Exp (X : Unit_Type) return Float;
--   function Log (X : Unit_Type) return Float;

--  
   function Sin (X : Angle_Type) return Unit_Type;
--     
--    function Sin (X, Cycle : Angle_Type) return Unit_Type;
--        
   function Cos (X : Angle_Type) return Unit_Type;
--        
--     function Cos (X, Cycle : Angle_Type) return Unit_Type;
--        
--     function Tan (X : Angle_Type) return Unit_Type;
--        
--     function Tan (X, Cycle : Angle_Type) return Unit_Type;
--        
--     function Cot (X : Angle_Type) return Unit_Type;
--        
--     function Cot (X, Cycle : Angle_Type) return Unit_Type;
--        
--     function Arcsin (X : Unit_Type) return Angle_Type;
--        
--     function Arcsin (X : Unit_Type; Cycle : Angle_Type) return Angle_Type;
--           
--     function Arccos (X  : Unit_Type) return Angle_Type;
--        
--     function Arccos  (X : Unit_Type; Cycle : Angle_Type) return Angle_Type;
         
   function Arctan
     (Y : Unit_Type;
      X : Unit_Type := 1.0) return Angle_Type;
         

   function Arctan
     (Y     : Unit_Type;
      X     : Unit_Type := 1.0;
      Cycle : Angle_Type) return Angle_Type;
      
         
--     function Arccot
--       (X : Unit_Type;
--        Y : Unit_Type := 1.0) return Angle_Type;
--           
--     function Arccot
--       (X     : Unit_Type;
--        Y     : Unit_Type := 1.0;
--        Cycle : Angle_Type) return Angle_Type;
--           



end Units.Numerics;
