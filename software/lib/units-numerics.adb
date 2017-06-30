with Ada.Numerics.Elementary_Functions; use Ada.Numerics;

package body Units.Numerics with
   SPARK_Mode => On
is

   function Sqrt (X : Base_Unit_Type) return Base_Unit_Type is
   begin
      return Base_Unit_Type( Elementary_Functions.Sqrt (Float (X)) );
   end Sqrt;

--     procedure Lemma_Log_Is_Monotonic (X, Y : Unit_Type) with
--       Ghost,
--       Pre => X > 0.0 and then Y > 0.0,
--       Contract_Cases => (X <= Y => Log (X) <= Log (Y),
--                          Y <  X => Log (Y) <= Log (X));

--    procedure Lemma_Log_Is_Monotonic (X, Y : Unit_Type)
--      is null with SPARK_Mode => Off;


   function Exp (X : Base_Unit_Type) return Base_Unit_Type is
   begin
      return Base_Unit_Type (Elementary_Functions.Exp (Float (X)));
   end Exp;


   function Log (X : Base_Unit_Type) return Base_Unit_Type is
   begin
      return Base_Unit_Type (Elementary_Functions.Log (Float (X)));
   end Log;


   function "**" (Left : Base_Unit_Type; Right : Float) return Base_Unit_Type is
   begin
      -- Elementary_Functions does not offer Pow, and "**" is for Natural exponents only.
      -- Thus: x=b**y => log_b(x)=y => log x/log b = y => log x = log b*y => x=exp(y*log b)
      -- with b=left, y=right
      declare
         ll  : constant Base_Unit_Type := Log (Left);
         arg : constant Base_Unit_Type := Base_Unit_Type (Right) * ll; -- TODO: ovf check might fail
      begin
         pragma Assert (arg < Log (Base_Unit_Type'Last)); -- TODO: assertion fails
         return Base_Unit_Type (Exp (arg));
      end;
   end "**";

   function Sin (X : Angle_Type) return Base_Unit_Type is
   begin
      return Base_Unit_Type( Elementary_Functions.Sin( Float( X ) ) );
   end Sin;

   -- header comment for Cos
   -- @req mine+2
   function Cos (X : Angle_Type) return Base_Unit_Type is
   begin
      --  @req foobar/2 @req nothing
      -- @req foobar/2
      return Base_Unit_Type( Elementary_Functions.Cos( Float( X ) ) );
   end Cos;
   -- footer comment for cos



   function Arctan
     (Y     : Base_Unit_Type'Base;
      X     : Base_Unit_Type'Base := 1.0;
      Cycle : Angle_Type)
      return Angle_Type is
   begin
      return Angle_Type (Elementary_Functions.Arctan (Y => Float (Y), X => Float (X), Cycle => Float (Cycle)));
   end Arctan;

   function Arctan
     (Y : Base_Unit_Type;
      X : Base_Unit_Type := 1.0)
      return Angle_Type is
   begin
      return Angle_Type (Elementary_Functions.Arctan (Y => Float (Y), X => Float (X)));
   end Arctan;

end Units.Numerics;
-- trailing package comment
