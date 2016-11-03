-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      CRC-8
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Checksum according to fletcher's algorithm

generic
   type Index_Type is (<>);
   type Element_Type is private;
package Generic_Unit with
SPARK_Mode is

   type Byte is mod 2**8;
   --type Array_Type is array (Integer range <>) of Element_Type;  
   
   type Checksum_Type is record
   	ck_a : Byte;
   	ck_b : Byte;
   end record;

   -- init
   --function Checksum(Data : Array_Type) return Checksum_Type;

   function Add (i1 : Index_Type; i2 : Index_Type) return Index_Type;
   

end Generic_Unit;
