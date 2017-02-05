with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Interfaces; use Interfaces;
procedure main with SPARK_Mode is

   package Efuncs is new Ada.Numerics.Generic_Elementary_Functions (Interfaces.IEEE_Float_32);
   package Efuncs64 is new Ada.Numerics.Generic_Elementary_Functions (Interfaces.IEEE_Float_64);



   machine_has_denorm : constant Boolean := Float'Denorm;
   pragma Assert (machine_has_denorm);

   machine_exp_max : constant Integer := Interfaces.IEEE_Float_32'Machine_Emax;
   float_32bit : constant Boolean := machine_exp_max = 128;
   pragma assert (float_32bit);

   -- float 32bit: 1+(significand)*2^(exp), where significand=23bit, exp=8bit signed (-127..128)
   -- smallest possible significant: 1.0 => smallest possible float: 2^-126 = 1.175E-38

   sub1 : Interfaces.IEEE_Float_32 := -1.1E-39; -- starting at ~-38 we get denormals here; compiler warns us
   sub2 : Interfaces.IEEE_Float_32 := 100.0;
   res  : Interfaces.IEEE_Float_32;

   sub64 : Interfaces.IEEE_Float_64 := 2.0E-308;
   sub4 : Interfaces.IEEE_Float_64;
begin

   -- Float Attributes: http://www.adaic.org/resources/add_content/standards/12rm/html/RM-A-5-3.html
   Put_Line ("Float Info:");
   Put_Line ("Machine Radix: "  & Integer'Image(Float'Machine_Radix) & ", Machine Mantissa: " & Integer'Image(Float'Machine_Mantissa));
   Put_Line ("Machine Exponent: "  & Integer'Image(Float'Machine_Emin) & " .. " & Integer'Image(Float'Machine_Emax));
   Put_Line ("Machine Denormals: "  & Boolean'Image(machine_has_denorm));
   Put_Line ("Machine Overflows: " & Boolean'Image(Float'Machine_Overflows));
   Put_Line ("Machine Rounds: " & Boolean'Image(Float'Machine_Rounds));
   Put_Line ("Signed Zeros: " & Boolean'Image(Float'Signed_Zeros));
   Put_Line ("Model Epsilon: " & Float'Image(Float'Model_Epsilon));
   Put_Line ("Model Small: " & Float'Image(Float'Model_Small));
   Put_Line ("Model Emin: " & Integer'Image(Float'Model_Emin));
   Put_Line ("Model Mantissa: " & Integer'Image(Float'Model_Mantissa));
   Put_Line ("Safe Range: "  & Float'Image(Float'Safe_First) & " .. " & Float'Image(Float'Safe_Last));

   pragma Assert (sub1 /= 0.0); -- this is still successful with a denormal

   sub4 := 1.12E-309;
   sub4 := Efuncs64.Sin(sub4);
   -- Put(IEEE_Float_64'Image(sub4));
   sub64 := sub64 * sub4;

   --res := Efuncs.cos (sub1*sub1);

   --Put_Line ("exp min=" & Integer'Image(machine_exp_min));
   res := sub1 - sub2; -- always okay

   res := sub1 / sub2; -- also okay
   res := sub1 + 1.0; -- also okay
   res := sub1 * sub1;
   pragma Assert (res in -1.0 .. 1.0);

   res := res * sub1;
end main;
