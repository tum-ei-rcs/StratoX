with Units; use Units;

package unav with SPARK_Mode is

   EARTH_RADIUS : constant Length_Type := 6378.137 * Kilo * Meter;

   function Get_Distance return Length_Type with
     Post => Get_Distance'Result in 0.0 * Meter .. 2.0*EARTH_RADIUS*180.0*Degree;
end unav;
