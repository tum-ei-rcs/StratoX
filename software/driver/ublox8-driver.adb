
with Units; use Units;

with Fletcher16;
with HIL; use HIL;
with HIL.UART; use type HIL.UART.Data_Type;
with Interfaces; use Interfaces;
with Config.Software;

with Logger;
with ULog.GPS;

with ublox8.Protocol; use ublox8.Protocol;
with Ada.Real_Time; use Ada.Real_Time;

package body ublox8.Driver with
Refined_State => (State => (G_position, G_heading))
is  
   package Fletcher16_Byte is new Fletcher16 (
                                                Index_Type => Natural, 
                                                Element_Type => Byte, 
                                                Array_Type => Byte_Array);
   
   
   G_position : GPS_Loacation_Type := 
      ( Longitude => 0.0 * Degree,
        Latitude  => 0.0 * Degree,
        Altitude  => 0.0 * Meter );

   G_heading : Heading_Type := NORTH;


   UBLOX_M8N : constant HIL.UART.Device_ID_Type := HIL.UART.GPS;


   procedure reset is
   begin
      null;
   end reset;


   procedure waitForSync(isReceived : out Boolean) is
      sync : Byte_Array (1 .. 2) := (others => Byte( 0 ));
      start : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      timeout : Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds( 100 );
   begin
      while sync(1) /= UBX_SYNC1 and now < start + timeout loop
         HIL.UART.read(UBLOX_M8N, sync(1 .. 1));
         now := Ada.Real_Time.Clock;
      end loop;
      HIL.UART.read(UBLOX_M8N, sync(2 .. 2));
      if sync(1) = UBX_SYNC1 and sync(2) = UBX_SYNC2 then
         isReceived := True;
      else 
         isReceived := False;
      end if;
   end waitForSync;

   procedure waitForAck(isReceived : out Boolean) is
      head : Byte_Array (3 .. 6) := (others => Byte( 0 ));
   begin
      waitForSync(isReceived);
      if isReceived then
         HIL.UART.read(UBLOX_M8N, head);
         if head(3) = UBX_CLASS_ACK and head(4) = UBX_ID_ACK_ACK and head(5) = UBX_LENGTH_ACK_ACK then
            Logger.log(Logger.DEBUG, "UBX Ack");
         elsif head(3) = UBX_CLASS_ACK and head(4) = UBX_ID_ACK_NAK and head(5) = UBX_LENGTH_ACK_ACK then
            Logger.log(Logger.DEBUG, "UBX NAK");
            isReceived := False;
         end if;
      end if;
   end waitForAck;

   procedure writeToDevice(header: UBX_Header_Array; data : Data_Type) is      
      cks : Fletcher16_Byte.Checksum_Type := Fletcher16_Byte.Checksum( header(3 .. 6) & data );
      check : UBX_Checksum_Array := (1 => cks.ck_a, 2 => cks.ck_b);
      isReceived : Boolean := False;
      retries : Natural := 3;
   begin
      while isReceived = False and retries > 0 loop
         HIL.UART.write(UBLOX_M8N, header & data & check);
         waitForAck(isReceived);
         retries := retries - 1;
      end loop;
      if retries = 0 then
         Logger.log(Logger.DEBUG, "Timeout");
      end if;
   end writeToDevice;
   
   
   procedure readFromDevice(data : out Data_Type) is
      
      head : Byte_Array (3 .. 6) := (others => Byte( 0 ));
      data_rx : Byte_Array (1 .. 92) := (others => Byte( 0 ));
      check : Byte_Array (1 .. 2) := (others => Byte( 0 ));
      cks : Fletcher16_Byte.Checksum_Type := (others => Byte( 0 ));
      isReceived : Boolean := False;
   begin
      data := (others => Byte( 0 ) );
      waitForSync(isReceived);
      if isReceived then
         
         HIL.UART.read(UBLOX_M8N, head);
         if head(3) = UBX_CLASS_NAV and head(4) = UBX_ID_NAV_PVT and head(5) = UBX_LENGTH_NAV_PVT then
            HIL.UART.read(UBLOX_M8N, data_rx);
            HIL.UART.read(UBLOX_M8N, check);
            
            cks := Fletcher16_Byte.Checksum( head & data_rx );
            if check(1) = cks.ck_a and check(2) = cks.ck_b then
               Logger.log(Logger.DEBUG, "UBX valid");
               data := data_rx;
            else
               data := (others => Byte( 0 ));
               Logger.log(Logger.DEBUG, "UBX invalid");
            end if;
            
         elsif head(3) = UBX_CLASS_ACK and head(4) = UBX_ID_ACK_ACK and head(5) = UBX_LENGTH_ACK_ACK then
            Logger.log(Logger.DEBUG, "UBX Ack");
         end if;  
         
         -- got class 1, id 3, length 16 -> NAV_STATUS
         Logger.log(Logger.DEBUG, "UBX msg class " & Integer'Image(Integer(head(3))) & ", id "
                    & Integer'Image(Integer(head(4))));
      end if;
   end readFromDevice;   


   procedure init is
      
      msg_cfg_prt_head : UBX_Header_Array := (1 => UBX_SYNC1,
                                              2 => UBX_SYNC2,
                                              3 => UBX_CLASS_CFG,
                                              4 => UBX_ID_CFG_PRT,
                                              5 => Byte(20),
                                              6 => Byte(0));
                                              
      msg_cfg_prt : Data_Type(0 .. 19) := (0 => UBX_TX_CFG_PRT_PORTID,
                                           2 => Byte(0),
                                           4 => Byte( 2#1100_0000# ), -- uart mode 8bit
                                           5 => Byte( 2#0000_1000# ), -- uart mode no parity, 1 stop bit
                                           8 => HIL.toBytes( Config.Software.UBLOX_BAUD_RATE_HZ )(1),
                                           9 => HIL.toBytes( Config.Software.UBLOX_BAUD_RATE_HZ )(2),
                                           12 => Byte( 1 ),  -- ubx protocol
                                           14 => Byte( 1 ),  -- ubx protocol
                                           16 => Byte( 0 ), -- flags
                                           others => Byte( 0 ) );
                                      
      msg_cfg_msg_head : UBX_Header_Array := (1 => UBX_SYNC1,
                                              2 => UBX_SYNC2,
                                              3 => UBX_CLASS_CFG,
                                              4 => UBX_ID_CFG_MSG,
                                              5 => Byte(3),  -- length
                                              6 => Byte(0));
                                              
      msg_cfg_msg : Data_Type(0 .. 2) := (0 => UBX_CLASS_NAV,
                                          1 => UBX_ID_NAV_PVT,
                                          2 => Byte( 10 ) );  -- rate in Hz?                                 
   begin
      null;
      -- 1. Set binary protocol (CFG-PRT, own message)
      writeToDevice(msg_cfg_prt_head, msg_cfg_prt);  -- no ACK is expected here

      -- 2. Set baudrate (CFG-PRT, again own message)

      -- 3. Set message rates (CFG-MSG)
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg);  -- implemented for ubx7+ modules only
      
      -- set other to 0
      msg_cfg_msg(2) := Byte( 0 );
      msg_cfg_msg(1) := UBX_ID_NAV_POSLLH;
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg);
      
      msg_cfg_msg(1) := UBX_ID_NAV_SOL;
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg);
      
      msg_cfg_msg(1) := UBX_ID_NAV_VELNED;
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg);  

      msg_cfg_msg(1) := UBX_ID_NAV_STATUS;
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg); 
      -- 4. set dynamic model
      
      
   end init;

   -- read measurements values. Should be called periodically.
   procedure update_val is
      data_rx : Data_Type(1 .. 92) := (others => 0);
      gpsmsg : ULog.GPS.Message;
   begin
      readFromDevice(data_rx);
      G_position.Longitude := Unit_Type(Float( HIL.toUnsigned_32( data_rx(24 .. 27) ) ) * 1.0e-7) * Degree;

      -- logging
      --gpsmsg.lon := G_position.Longitude;
      Logger.log_ulog (level => Logger.SENSOR, msg => gpsmsg);
   end update_val;


   function get_Position return GPS_Loacation_Type is
   begin
      return G_position;
   end get_Position;

   function get_Direction return Heading_Type is
   begin
      return G_heading;
   end get_Direction;

   procedure perform_Self_Check (Status : out Error_Type) is
   begin
      null;
   end perform_Self_Check;

end ublox8.Driver;
