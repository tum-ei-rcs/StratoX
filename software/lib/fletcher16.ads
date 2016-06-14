-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      CRC-8
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Checksum according to fletcher's algorithm


with HIL;

package Fletcher16 with
SPARK_Mode is

   subtype Byte is HIL.Byte;
   
   subtype Byte_Array is HIL.Byte_Array;

   type Checksum_Type is record
   	ck_a : Byte;
   	ck_b : Byte;
   end record;

   -- init
   function Checksum(Data : Byte_Array) return Checksum_Type;


end Fletcher16;
