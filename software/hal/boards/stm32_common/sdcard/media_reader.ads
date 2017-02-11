with Interfaces; use Interfaces;
with HIL;

--  TODO: rewrite; separate SPARK from non-SPARK.
--  this package provides data types (Block), which are required in SPARK code,
--  but also uses access, which isn't.
package Media_Reader is -- SPARK_Mode => Auto

   type Media_Controller is limited interface;
   type Media_Controller_Access is access all Media_Controller'Class;

   type Block is array (Unsigned_16 range <>) of Unsigned_8;
   --subtype Block is HIL.Byte_Array;

   function Block_Size
     (Controller : in out Media_Controller) return Unsigned_32 is abstract;

   function Read_Block
     (Controller   : in out Media_Controller;
      Block_Number : Unsigned_32;
      Data         : out Block) return Boolean is abstract;

   function Write_Block
     (Controller   : in out Media_Controller;
      Block_Number : Unsigned_32;
      Data         : Block) return Boolean is abstract;

end Media_Reader;
