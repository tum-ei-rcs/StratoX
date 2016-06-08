-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      CRC-8
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Checksum according to fletcher's algorithm


with HIL;

package Fletcher16 is



   -- init
   function Checksum(Data : Byte_Array) return Checksum_Type is
   	result : Checksum_Type := (0 , 0);
   begin 
   	for i in range 1 .. Data'Length loop
   		result.ck_a :=  result.ck_a + Data(i);
   		result.ck_b := result.ck_b + result.ck_a;
   	end loop;
   end Checksum;


end Fletcher16;
