package body unav with SPARK_Mode is

   function Get_Distance return Length_Type is
      darc : Unit_Type := 0.5;
   begin
      return 2.0 * EARTH_RADIUS * darc;
   end Get_Distance;
end unav;
