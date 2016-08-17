--  Institution: Technische Universitaet Muenchen
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--  Authors:     Martin Becker (becker@rcs.ei.tum.de)
with Interfaces; use Interfaces;


package body NVRAM with SPARK_Mode => On,   -- Somehow this package includes interrupts, which are accesses
   Refined_State => (Memory_State => null)
is



   procedure Init is null;

   procedure Self_Check (Status : out Boolean) is null;

   procedure Load (variable : Variable_Name; data : out HIL.Byte) is
   begin
      data := HIL.Byte( 0 );
   end Load;

   procedure Load (variable : in Variable_Name; data : out Float) is
   begin
      data := 0.0;
   end Load;

   procedure Store (variable : Variable_Name; data : in HIL.Byte) is null;

   procedure Store (variable : in Variable_Name; data : in Float) is null;

   procedure Reset is null;

end NVRAM;
