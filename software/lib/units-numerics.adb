with Ada.Numerics.Elementary_Functions; use Ada.Numerics;

package body Units.Numerics with
   SPARK_Mode => Off
is

   function Sqrt (X : Unit_Type) return Float is
   begin
      return Elementary_Functions.Sqrt (Float (X));
   end Sqrt;

   function "**"
     (Left  : Unit_Type;
      Right : Integer)
      return Float is
   begin
      return Elementary_Functions."**" (Float (Left), Float (Right));
   end "**";

   function "**" (Left : Unit_Type; Right : Float) return Unit_Type is
   begin
      return Unit_Type( Elementary_Functions.Exp( Right * Elementary_Functions.Log( Float(Left) ) ) );
   end "**";


   function Sin (X : Angle_Type) return Unit_Type is
   begin
      return Unit_Type( Elementary_Functions.Sin( Float( X ) ) );
   end Sin;

   -- header comment for Cos
   -- @req mine+2
   function Cos (X : Angle_Type) return Unit_Type is
   begin
      --  @req foobar/2 @req nothing
      -- @req foobar/2
        return Unit_Type( Elementary_Functions.Cos( Float( X ) ) );
   end Cos;
   -- footer comment for cos



   function Arctan
     (Y     : Unit_Type;
      X     : Unit_Type := 1.0;
      Cycle : Angle_Type)
      return Angle_Type is
   begin
      return Angle_Type (Elementary_Functions.Arctan (Float (Y), Float (X), Float (Cycle)));
   end Arctan;

   function Arctan
     (Y : Unit_Type;
      X : Unit_Type := 1.0)
      return Angle_Type is
   begin
      return Angle_Type (Elementary_Functions.Arctan (Float (Y), Float (X)));
   end Arctan;

end Units.Numerics;
-- trailing package comment
