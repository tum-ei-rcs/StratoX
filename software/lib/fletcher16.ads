-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      CRC-8
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Checksum according to fletcher's algorithm


with HIL;

generic
   type Index_Type is (<>);
   type Element_Type is private;
   type Array_Type is array (Index_Type range <>) of Element_Type;
   with function "+" (Left : HIL.Byte; Right : Element_Type) return HIL.Byte is <>;
package Fletcher16 with
SPARK_Mode is

   subtype Byte is HIL.Byte;
   --type Array_Type is array (Integer range <>) of Element_Type;  
   
   type Checksum_Type is record
   	ck_a : Byte;
   	ck_b : Byte;
   end record;

   -- init
   function Checksum(Data : Array_Type) return Checksum_Type;


end Fletcher16;
