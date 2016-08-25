with Generic_Bounded_Image;

pragma Elaborate_All (Generic_Bounded_Image);

--  @summary functions to provide a string image of numbers
--  overapproximating the length, otherwise we would need a
--  separate body for each data type. This is tight enough
--  in most cases.
package Bounded_Image with SPARK_Mode is

   function Integer_Img is new Generic_Bounded_Image.Image_32 (Integer) with Inline;
   function Natural_Img is new Generic_Bounded_Image.Image_32 (Natural) with Inline;

end Bounded_Image;
