with Generic_Bounded_Image;
with Interfaces; use Interfaces;

pragma Elaborate_All (Generic_Bounded_Image);

--  @summary functions to provide a string image of numbers
--  overapproximating the length, otherwise we would need a
--  separate body for each data type. This is tight enough
--  in most cases.
package Bounded_Image with SPARK_Mode is

   function Integer_Img is new Generic_Bounded_Image.Image_32 (Integer) with Inline;
   function Natural_Img is new Generic_Bounded_Image.Image_32 (Natural) with Inline;
   function Unsigned8_Img is new Generic_Bounded_Image.Image_4 (Unsigned_8) with Inline;
   function Integer8_Img is new Generic_Bounded_Image.Image_4 (Integer_8) with Inline;

end Bounded_Image;
