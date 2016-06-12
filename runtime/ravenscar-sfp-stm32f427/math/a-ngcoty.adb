------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--   A D A . N U M E R I C S . G E N E R I C _ C O M P L E X _ T Y P E S    --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 1992-2015, Free Software Foundation, Inc.         --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

--  This is the Ada Cert Math specific version of a-ngcoty.adb

with Ada.Numerics.Long_Long_Elementary_Functions;
use Ada.Numerics.Long_Long_Elementary_Functions;

package body Ada.Numerics.Generic_Complex_Types is

   subtype R is Real'Base;

   subtype LLF is Long_Long_Float;

   Two_Pi  : constant R := R (2.0) * Pi;
   Half_Pi : constant R := Pi / R (2.0);

   ---------
   -- "*" --
   ---------

   function "*" (Left, Right : Complex) return Complex is
      Scale : constant R := R (R'Machine_Radix) ** ((R'Machine_Emax - 1) / 2);
      --  In case of overflow, scale the operands by the largest power of the
      --  radix (to avoid rounding error), so that the square of the scale does
      --  not overflow itself.

      X : R;
      Y : R;

   begin
      X := Left.Re * Right.Re - Left.Im * Right.Im;
      Y := Left.Re * Right.Im + Left.Im * Right.Re;

      --  If either component overflows, try to scale (skip in fast math mode)

      if not Standard'Fast_Math then

         --  Note that the test below is written as a negation. This is to
         --  account for the fact that X and Y may be NaNs, because both of
         --  their operands could overflow. Given that all operations on NaNs
         --  return false, the test can only be written thus.

         if not (abs (X) <= R'Last) then
            X := Scale**2 * ((Left.Re / Scale) * (Right.Re / Scale) -
                             (Left.Im / Scale) * (Right.Im / Scale));
         end if;

         if not (abs (Y) <= R'Last) then
            Y := Scale**2 * ((Left.Re / Scale) * (Right.Im / Scale)
                           + (Left.Im / Scale) * (Right.Re / Scale));
         end if;
      end if;

      return (X, Y);
   end "*";

   function "*" (Left, Right : Imaginary) return Real'Base is
   begin
      return -(R (Left) * R (Right));
   end "*";

   function "*" (Left : Complex; Right : Real'Base) return Complex is
   begin
      return Complex'(Left.Re * Right, Left.Im * Right);
   end "*";

   function "*" (Left : Real'Base; Right : Complex) return Complex is
   begin
      return (Left * Right.Re, Left * Right.Im);
   end "*";

   function "*" (Left : Complex; Right : Imaginary) return Complex is
   begin
      return Complex'(-(Left.Im * R (Right)), Left.Re * R (Right));
   end "*";

   function "*" (Left : Imaginary; Right : Complex) return Complex is
   begin
      return Complex'(-(R (Left) * Right.Im), R (Left) * Right.Re);
   end "*";

   function "*" (Left : Imaginary; Right : Real'Base) return Imaginary is
   begin
      return Left * Imaginary (Right);
   end "*";

   function "*" (Left : Real'Base; Right : Imaginary) return Imaginary is
   begin
      return Imaginary (Left * R (Right));
   end "*";

   ----------
   -- "**" --
   ----------

   function "**" (Left : Complex; Right : Integer) return Complex is
      Exp    : Integer := Right;
      Factor : Complex := Left;
      Result : Complex := (1.0, 0.0);

   begin
      --  We use the standard logarithmic approach, Exp gets shifted right
      --  testing successive low order bits and Factor is the value of the
      --  base raised to the next power of 2. For positive exponents we
      --  multiply the result by this factor, for negative exponents, we
      --  divide by this factor.

      if Exp >= 0 then

         --  For a positive exponent, if we get a constraint error during
         --  this loop, it is an overflow, and the constraint error will
         --  simply be passed on to the caller.

         while Exp /= 0 loop
            if Exp rem 2 /= 0 then
               Result := Result * Factor;
            end if;

            Factor := Factor * Factor;
            Exp    := Exp / 2;
         end loop;

         return Result;

      else -- Exp < 0 then

         --  For the negative exponent case, a constraint error during this
         --  calculation happens if Factor gets too large, and the proper
         --  response is to return 0.0, since what we essentially have is
         --  1.0 / infinity, and the closest model number will be zero.

         begin
            while Exp /= 0 loop
               if Exp rem 2 /= 0 then
                  Result := Result * Factor;
               end if;

               Factor := Factor * Factor;
               Exp    := Exp / 2;
            end loop;

            return R'(1.0) / Result;

         exception
            when Constraint_Error =>
               return (0.0, 0.0);
         end;
      end if;
   end "**";

   function "**" (Left : Imaginary; Right : Integer) return Complex is
      M : constant R := R (Left) ** Right;
   begin
      case Right mod 4 is
         when 0 => return (M,   0.0);
         when 1 => return (0.0, M);
         when 2 => return (-M,  0.0);
         when 3 => return (0.0, -M);
         when others => raise Program_Error;
      end case;
   end "**";

   ---------
   -- "+" --
   ---------

   function "+" (Right : Complex) return Complex is
   begin
      return Right;
   end "+";

   function "+" (Left, Right : Complex) return Complex is
   begin
      return Complex'(Left.Re + Right.Re, Left.Im + Right.Im);
   end "+";

   function "+" (Right : Imaginary) return Imaginary is
   begin
      return Right;
   end "+";

   function "+" (Left, Right : Imaginary) return Imaginary is
   begin
      return Imaginary (R (Left) + R (Right));
   end "+";

   function "+" (Left : Complex; Right : Real'Base) return Complex is
   begin
      return Complex'(Left.Re + Right, Left.Im);
   end "+";

   function "+" (Left : Real'Base; Right : Complex) return Complex is
   begin
      return Complex'(Left + Right.Re, Right.Im);
   end "+";

   function "+" (Left : Complex; Right : Imaginary) return Complex is
   begin
      return Complex'(Left.Re, Left.Im + R (Right));
   end "+";

   function "+" (Left : Imaginary; Right : Complex) return Complex is
   begin
      return Complex'(Right.Re, R (Left) + Right.Im);
   end "+";

   function "+" (Left : Imaginary; Right : Real'Base) return Complex is
   begin
      return Complex'(Right, R (Left));
   end "+";

   function "+" (Left : Real'Base; Right : Imaginary) return Complex is
   begin
      return Complex'(Left, R (Right));
   end "+";

   ---------
   -- "-" --
   ---------

   function "-" (Right : Complex) return Complex is
   begin
      return (-Right.Re, -Right.Im);
   end "-";

   function "-" (Left, Right : Complex) return Complex is
   begin
      return (Left.Re - Right.Re, Left.Im - Right.Im);
   end "-";

   function "-" (Right : Imaginary) return Imaginary is
   begin
      return Imaginary (-R (Right));
   end "-";

   function "-" (Left, Right : Imaginary) return Imaginary is
   begin
      return Imaginary (R (Left) - R (Right));
   end "-";

   function "-" (Left : Complex; Right : Real'Base) return Complex is
   begin
      return Complex'(Left.Re - Right, Left.Im);
   end "-";

   function "-" (Left : Real'Base; Right : Complex) return Complex is
   begin
      return Complex'(Left - Right.Re, -Right.Im);
   end "-";

   function "-" (Left : Complex; Right : Imaginary) return Complex is
   begin
      return Complex'(Left.Re, Left.Im - R (Right));
   end "-";

   function "-" (Left : Imaginary; Right : Complex) return Complex is
   begin
      return Complex'(-Right.Re, R (Left) - Right.Im);
   end "-";

   function "-" (Left : Imaginary; Right : Real'Base) return Complex is
   begin
      return Complex'(-Right, R (Left));
   end "-";

   function "-" (Left : Real'Base; Right : Imaginary) return Complex is
   begin
      return Complex'(Left, -R (Right));
   end "-";

   ---------
   -- "/" --
   ---------

   function "/" (Left, Right : Complex) return Complex is
      A : constant R := Left.Re;
      B : constant R := Left.Im;
      C : constant R := Right.Re;
      D : constant R := Right.Im;

   begin
      if C = 0.0 and then D = 0.0 then
         raise Constraint_Error;
      else
         return Complex'(Re => ((A * C) + (B * D)) / (C ** 2 + D ** 2),
                         Im => ((B * C) - (A * D)) / (C ** 2 + D ** 2));
      end if;
   end "/";

   function "/" (Left, Right : Imaginary) return Real'Base is
   begin
      return R (Left) / R (Right);
   end "/";

   function "/" (Left : Complex; Right : Real'Base) return Complex is
   begin
      return Complex'(Left.Re / Right, Left.Im / Right);
   end "/";

   function "/" (Left : Real'Base; Right : Complex) return Complex is
      A : constant R := Left;
      C : constant R := Right.Re;
      D : constant R := Right.Im;

   begin
      return Complex'(Re =>   (A * C) / (C ** 2 + D ** 2),
                      Im => -((A * D) / (C ** 2 + D ** 2)));
   end "/";

   function "/" (Left : Complex; Right : Imaginary) return Complex is
      A : constant R := Left.Re;
      B : constant R := Left.Im;
      D : constant R := R (Right);

   begin
      return (B / D,  -(A / D));
   end "/";

   function "/" (Left : Imaginary; Right : Complex) return Complex is
      B : constant R := R (Left);
      C : constant R := Right.Re;
      D : constant R := Right.Im;

   begin
      return (Re => B * D / (C ** 2 + D ** 2),
              Im => B * C / (C ** 2 + D ** 2));
   end "/";

   function "/" (Left : Imaginary; Right : Real'Base) return Imaginary is
   begin
      return Imaginary (R (Left) / Right);
   end "/";

   function "/" (Left : Real'Base; Right : Imaginary) return Imaginary is
   begin
      return Imaginary (-(Left / R (Right)));
   end "/";

   ---------
   -- "<" --
   ---------

   function "<" (Left, Right : Imaginary) return Boolean is
   begin
      return R (Left) < R (Right);
   end "<";

   ----------
   -- "<=" --
   ----------

   function "<=" (Left, Right : Imaginary) return Boolean is
   begin
      return R (Left) <= R (Right);
   end "<=";

   ---------
   -- ">" --
   ---------

   function ">" (Left, Right : Imaginary) return Boolean is
   begin
      return R (Left) > R (Right);
   end ">";

   ----------
   -- ">=" --
   ----------

   function ">=" (Left, Right : Imaginary) return Boolean is
   begin
      return R (Left) >= R (Right);
   end ">=";

   -----------
   -- "abs" --
   -----------

   function "abs" (Right : Imaginary) return Real'Base is
   begin
      return abs R (Right);
   end "abs";

   --------------
   -- Argument --
   --------------

   function Argument (X : Complex) return Real'Base is
      A   : constant R := X.Re;
      B   : constant R := X.Im;
      Arg : R;

   begin
      if B = 0.0 then
         if A >= 0.0 then
            return 0.0;
         else
            return R'Copy_Sign (Pi, B);
         end if;

      elsif A = 0.0 then
         if B >= 0.0 then
            return Half_Pi;
         else
            return -Half_Pi;
         end if;

      else
         Arg := R (Arctan (LLF (abs (B / A))));

         if A > 0.0 then
            if B > 0.0 then
               return Arg;
            else                  --  B < 0.0
               return -Arg;
            end if;

         else                     --  A < 0.0
            if B >= 0.0 then
               return Pi - Arg;
            else                  --  B < 0.0
               return -(Pi - Arg);
            end if;
         end if;
      end if;

   exception
      when Constraint_Error =>
         if B > 0.0 then
            return Half_Pi;
         else
            return -Half_Pi;
         end if;
   end Argument;

   function Argument (X : Complex; Cycle : Real'Base) return Real'Base is
   begin
      if Cycle > 0.0 then
         return Argument (X) * Cycle / Two_Pi;
      else
         raise Argument_Error;
      end if;
   end Argument;

   ----------------------------
   -- Compose_From_Cartesian --
   ----------------------------

   function Compose_From_Cartesian (Re, Im : Real'Base) return Complex is
   begin
      return (Re, Im);
   end Compose_From_Cartesian;

   function Compose_From_Cartesian (Re : Real'Base) return Complex is
   begin
      return (Re, 0.0);
   end Compose_From_Cartesian;

   function Compose_From_Cartesian (Im : Imaginary) return Complex is
   begin
      return (0.0, R (Im));
   end Compose_From_Cartesian;

   ------------------------
   -- Compose_From_Polar --
   ------------------------

   function Compose_From_Polar
     (Modulus  : Real'Base;
      Argument : Real'Base) return Complex
   is
   begin
      if Modulus = 0.0 then
         return (0.0, 0.0);
      else
         return (Modulus * R (Cos (LLF (Argument))),
                 Modulus * R (Sin (LLF (Argument))));
      end if;
   end Compose_From_Polar;

   function Compose_From_Polar
     (Modulus  : Real'Base;
      Argument : Real'Base;
      Cycle    : Real'Base) return Complex
   is
      Arg : Real'Base;

   begin
      if Modulus = 0.0 then
         return (0.0, 0.0);

      elsif Cycle > 0.0 then
         if Argument = 0.0 then
            return (Modulus, 0.0);

         elsif Argument = Cycle / 4.0 then
            return (0.0, Modulus);

         elsif Argument = Cycle / 2.0 then
            return (-Modulus, 0.0);

         elsif Argument = 3.0 * Cycle / R (4.0) then
            return (0.0, -Modulus);
         else
            Arg := Two_Pi * Argument / Cycle;
            return (Modulus * R (Cos (LLF (Arg))),
                    Modulus * R (Sin (LLF (Arg))));
         end if;
      else
         raise Argument_Error;
      end if;
   end Compose_From_Polar;

   ---------------
   -- Conjugate --
   ---------------

   function Conjugate (X : Complex) return Complex is
   begin
      return Complex'(X.Re, -X.Im);
   end Conjugate;

   --------
   -- Im --
   --------

   function Im (X : Complex) return Real'Base is
   begin
      return X.Im;
   end Im;

   function Im (X : Imaginary) return Real'Base is
   begin
      return R (X);
   end Im;

   -------------
   -- Modulus --
   -------------

   function Modulus (X : Complex) return Real'Base is
      Im2 : R;
      Re2 : R;

   begin
      begin
         Re2 := X.Re ** 2;

         --  To compute (a**2 + b**2) ** (0.5) when a**2 may be out of bounds,
         --  compute a * (1 + (b/a) **2) ** (0.5). On a machine where the
         --  squaring does not raise constraint_error but generates infinity,
         --  we can use an explicit comparison to determine whether to use
         --  the scaling expression.

         --  The scaling expression is computed in double format throughout
         --  in order to prevent inaccuracies on machines where not all
         --  immediate expressions are rounded, such as PowerPC.

         --  ??? same weird test, why not Re2 > R'Last ???
         if not (Re2 <= R'Last) then
            raise Constraint_Error;
         end if;

      exception
         when Constraint_Error =>
            return
              R (LLF (abs (X.Re))
                * Sqrt (1.0 + (LLF (X.Im) / LLF (X.Re)) ** 2));
      end;

      begin
         Im2 := X.Im ** 2;

         --  ??? same weird test
         if not (Im2 <= R'Last) then
            raise Constraint_Error;
         end if;

      exception
         when Constraint_Error =>
            return
              R (LLF (abs (X.Im))
                * Sqrt (1.0 + (LLF (X.Re) / LLF (X.Im)) ** 2));
      end;

      --  Now deal with cases of underflow. If only one of the squares
      --  underflows, return the modulus of the other component. If both
      --  squares underflow, use scaling as above.

      if Re2 = 0.0 then
         if X.Re = 0.0 then
            return abs (X.Im);

         elsif Im2 = 0.0 then
            if X.Im = 0.0 then
               return abs (X.Re);

            else
               if abs (X.Re) > abs (X.Im) then
                  return
                    R (LLF (abs (X.Re))
                      * Sqrt (1.0 + (LLF (X.Im) / LLF (X.Re)) ** 2));
               else
                  return
                    R (LLF (abs (X.Im))
                      * Sqrt (1.0 + (LLF (X.Re) / LLF (X.Im)) ** 2));
               end if;
            end if;

         else
            return abs (X.Im);
         end if;

      elsif Im2 = 0.0 then
         return abs (X.Re);

      --  In all other cases, the naive computation will do

      else
         return R (Sqrt (LLF (Re2 + Im2)));
      end if;
   end Modulus;

   --------
   -- Re --
   --------

   function Re (X : Complex) return Real'Base is
   begin
      return X.Re;
   end Re;

   ------------
   -- Set_Im --
   ------------

   procedure Set_Im (X : in out Complex; Im : Real'Base) is
   begin
      X.Im := Im;
   end Set_Im;

   procedure Set_Im (X : out Imaginary; Im : Real'Base) is
   begin
      X := Imaginary (Im);
   end Set_Im;

   ------------
   -- Set_Re --
   ------------

   procedure Set_Re (X : in out Complex; Re : Real'Base) is
   begin
      X.Re := Re;
   end Set_Re;

end Ada.Numerics.Generic_Complex_Types;
