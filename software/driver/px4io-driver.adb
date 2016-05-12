
with HIL.UART; use type HIL.UART.Data_Type;
with PX4IO.Protocol; use PX4IO.Protocol;
with HIL;
with CRC8;

package body PX4IO.Driver is

   
   subtype Page_Type is HIL.Byte;
   subtype Offset_Type is HIL.Byte;
   
   subtype Data_Type is HIL.UART.Data_Type;
   
   
   procedure write(page : Page_Type; offset : Offset_Type; data : Data_Type) is
      Data_TX : HIL.UART.Data_Type := (
                                       1 => HIL.Byte(page),
                                       2 => HIL.Byte(offset)
                                       ) & data;
   begin
      HIL.UART.write(HIL.UART.PX4IO, Data_TX);
   end write;
   
   procedure read(page : Page_Type; offset : Offset_Type; data : out Data_Type) is
      Data_TX : HIL.UART.Data_Type(1 .. 5) := (     -- maximum 68 (4 + 64), but is this necessary?
                                               1 => HIL.Byte( 1 ),
                                               2 => HIL.Byte( 0 ),
                                               3 => HIL.Byte(page),
                                               4 => HIL.Byte(offset),
                                               5 => HIL.Byte( 0 )
                                               );
      Data_RX : HIL.UART.Data_Type(1 .. (4+data'Length)) := ( others => 0 );
   begin
      Data_TX(2) := CRC8.calculateCRC8( Data_TX );
      HIL.UART.write(HIL.UART.PX4IO, Data_TX);
      HIL.UART.read(HIL.UART.PX4IO, Data_RX);
      data(1) := Data_RX(5);
   end read;   

   -- init
   procedure initialize is
      protocol : Data_Type(1 .. 1) := (1 => 0);
   begin
	read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_PROTOCOL_VERSION, protocol);
   end initialize;

   procedure set_Servo_Angle(number : Servo_Number_Type; angle : Servo_Angle_Type) is
   begin
      null;
   end set_Servo_Angle;

end PX4IO.Driver;
