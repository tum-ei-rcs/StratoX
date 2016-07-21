with Ada.Text_IO;

package body HIL.UART is
   procedure configure is null;

   procedure write (Device : in Device_ID_Type; Data : in Data_Type) is
   begin
      --ada.Text_IO.Put (String (Data));
      null;
   end write;

   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is
   begin
      null;
   end;

   function toData_Type (Message : String) return Data_Type is
      a : Data_Type(1..2);
   begin
      return a;
   end;
end HIL.UART;
