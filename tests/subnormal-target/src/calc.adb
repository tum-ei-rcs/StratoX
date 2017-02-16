package body calc with SPARK_Mode is

   function calc (f1, f2: Float) return Float is
   begin
      return f1 * f2; -- Float overflow check proved, but it throws an exception because of underflow.
   end calc;


end calc;
