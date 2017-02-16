package body calc with SPARK_Mode is

   procedure Forgetful_Assert (X, Y : out Integer) with
     SPARK_Mode
   is
   begin
      X := 1;
      Y := 2;

      pragma Assert (X = 1);
      pragma Assert (Y = 2);

      pragma Assert_And_Cut (X > 0); --  also forgets about Y

      pragma Assert (Y = 2);

      pragma Assert (X > 0);
      pragma Assert (X = 1);
   end Forgetful_Assert;

end calc;
