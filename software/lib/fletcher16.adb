-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      CRC-8
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Checksum according to fletcher's algorithm


with HIL;
with Interfaces; use Interfaces;


package body Fletcher16 with SPARK_Mode is



   -- init
   function Checksum(Data : Array_Type) return Checksum_Type is
      result : Checksum_Type := (0 , 0);
   begin 
      for i in Data'Range loop
         --         result.ck_a := result.ck_a + Element_Type'Pos (Data (i));
         result.ck_a := result.ck_a + Data (i); -- Byte + Element_Type
         result.ck_b := result.ck_b + result.ck_a;
      end loop;
      return result;
   end Checksum;


end Fletcher16;
