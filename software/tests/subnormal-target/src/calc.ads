package calc with SPARK_Mode is

   function calc (f1, f2: Float) return Float with
     Pre => f1 in -1000.0 .. 1000.0 and f2 in -1000.0 .. 1000.0;

end calc;
