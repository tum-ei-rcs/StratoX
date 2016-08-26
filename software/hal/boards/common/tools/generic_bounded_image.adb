--  @summary functions to provide a string image of numbers
package body Generic_Bounded_Image with SPARK_Mode is

   function Image_32 (item : T) return String is
      res : constant String := T'Image (item);
      pragma Assume (res'Length > 0);
      len : constant Natural := res'Length;
      max : constant Natural := (if len > 32 then 32 else len);
   begin
      declare
         ret : String (1 .. max) := res (res'First .. res'First - 1 + max);
      begin
         return ret;
      end;
   end Image_32;


   function Image_4 (item : T) return String is
      res : constant String := T'Image (item);
      pragma Assume (res'Length > 0);
      len : constant Natural := res'Length;
      max : constant Natural := (if len > 4 then 4 else len);
   begin
      declare
         ret : String (1 .. max) := res (res'First .. res'First - 1 + max);
      begin
         return ret;
      end;
   end Image_4;

end Generic_Bounded_Image;
