-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
-- Module: Helper
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Helper functions
-- 
-- ToDo:
-- [ ] Implementation


package Helper is


  function addWrap( 
    x   : Integer; 
    inc : Integer)
  return Integer
  is ( if x + inc > x'Last then x + inc - x'Last
       else x + inc );

  function deltaWrap( 
    low  : Integer; 
    high : Integer) 
  return Integer 
  is ( if low < high then (high - low)
       else (high'Last - low) + (high - low'First) );





   --  Saturate a Float value within a given range.
   function Saturate
     (Value     : Float;
      Min_Value : Float;
      Max_Value : Float) return Float is
     (if Value < Min_Value then
         Min_Value
      elsif Value > Max_Value then
         Max_Value
      else
         Value);
   pragma Inline (Saturate);

end Helper;