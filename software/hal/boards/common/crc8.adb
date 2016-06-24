with Interfaces; use Interfaces;

package body CRC8 is

   -- init

   function calculateCRC8 (Data : Byte_Array) return Byte is
      crc : Byte := 0;

   begin
      for pos in Data'Range loop
         crc := crc8_tab (crc xor Data (pos));    -- loop over all bytes
      end loop;

      return crc;
   end calculateCRC8;

end CRC8;
