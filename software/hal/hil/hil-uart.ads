

package HIL.UART is

   type Device_ID_Type is (GPS, Console);

   type Data_Type is array(Natural range <>) of Byte;
   
   procedure configure;

   procedure write (Device : in Device_ID_Type; Data : in Data_Type);

   procedure read (Device : in Device_ID_Type; Data : out Data_Type);

   function toData_Type( Message : String ) return Data_Type;

end HIL.UART;
