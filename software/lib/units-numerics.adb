

with Ada.Numerics.Elementary_Functions; use Ada.Numerics;

package body Units.Numerics is


function Sqrt (X : Unit_Type) return Float is
begin
      return Elementary_Functions.Sqrt( Float( X ) );
end Sqrt;

function "**" (Left : Unit_Type; Right : Integer) return Float is
begin
      return Elementary_Functions."**"( Float( Left ), Float( Right ) );
end "**";

function Arctan
     (Y     : Unit_Type;
      X     : Unit_Type := 1.0;
      Cycle : Angle_Type) return Angle_Type is
begin
     return Angle_Type ( Elementary_Functions.Arctan( Float( X ), Float( Y ), Float( Cycle ) ) );
end Arctan;


function Arctan
     (Y     : Unit_Type;
      X     : Unit_Type := 1.0) return Angle_Type is
begin
     return Angle_Type ( Elementary_Functions.Arctan( Float( X ), Float( Y ) ) );
end Arctan;

end Units.Numerics;
