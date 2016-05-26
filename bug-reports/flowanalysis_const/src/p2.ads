with Interfaces; use Interfaces;

package p2 with
  SPARK_Mode
--  Abstract_State => (State with External)
is
    some_register : Unsigned_8 with Volatile, Async_Readers, Effective_Writes;

    some_constant : constant Unsigned_16 := 22_027;
    procedure foo;
end p2;
