with Ada.Text_IO; use Ada.Text_IO;

package body mylog with SPARK_Mode is
   procedure Print (m : logmsg) is
   begin
      case m.typ is
         when NONE => Put ("NONE");
         when GPS => Put ("GPS: ");
         when TEXT => Put ("TXT: ");
      end case;
   end Print;
end mylog;
