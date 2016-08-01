
with Units; use Units;

with Fletcher16;
with HIL; use HIL;
with HIL.Config; use HIL.Config;
with HIL.UART; use type HIL.UART.Data_Type;
with HIL.Devices;
with Interfaces; use Interfaces;
with Config.Software;

with Logger;
with ULog;

with ublox8.Protocol; use ublox8.Protocol;
with Ada.Real_Time; use Ada.Real_Time;

package body ublox8.Driver with
SPARK_Mode,
Refined_State => (State => (G_GPS_Message, G_heading))
is  
   package Fletcher16_Byte is new Fletcher16 (
                                                Index_Type => Natural, 
                                                Element_Type => Byte, 
                                                Array_Type => Byte_Array);
   

   G_heading : Heading_Type := NORTH;
   
   G_GPS_Message : GPS_Message_Type := 
      ( year => 0,
        month => 1,
        day => 1,
        hour => 0,
        minute => 0,
        second => 0,
        fix => NO_FIX,
        sats => 0,
        lon => 0.0 * Degree,
        lat => 0.0 * Degree,
        alt => 0.0 * Meter,
        speed => 0.0 * Meter / Second );


   UBLOX_M8N : constant HIL.UART.Device_ID_Type := HIL.Devices.GPS;


   procedure reset is
   begin
      null;
   end reset;


   procedure waitForSync(isReceived : out Boolean) is
      sync : Byte_Array (1 .. 2) := (others => Byte( 0 ));
      start : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      timeout : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds( 100 );
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
            Logger.log_console(Logger.DEBUG, "UBX Ack");
         elsif head(3) = UBX_CLASS_ACK and head(4) = UBX_ID_ACK_NAK and head(5) = UBX_LENGTH_ACK_ACK then
            Logger.log_console(Logger.DEBUG, "UBX NAK");
            isReceived := False;
         end if;
      end if;
   end waitForAck;

   procedure writeToDevice(header: UBX_Header_Array; data : Data_Type) is      
      cks : constant Fletcher16_Byte.Checksum_Type := Fletcher16_Byte.Checksum( header(3 .. 6) & data );
      check : constant UBX_Checksum_Array := (1 => cks.ck_a, 2 => cks.ck_b);
      isReceived : Boolean := False;
      retries : Natural := 1;
      now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      while isReceived = False and retries > 0 loop
         HIL.UART.write(UBLOX_M8N, header & data & check);
         delay until now + Milliseconds(2);
         waitForAck(isReceived);
         retries := retries - 1;
      end loop;
      if retries = 0 then
         Logger.log_console(Logger.DEBUG, "Timeout");
      end if;
   end writeToDevice;
   
   
   procedure readFromDevice(data : out Data_Type; isValid : out Boolean) is
      
      head : Byte_Array (3 .. 6) := (others => Byte( 0 ));
      data_rx : Byte_Array (0 .. HIL.UART.BUFFER_MAX - 1) := (others => Byte( 0 ));
      message : Byte_Array (0 .. 91) := (others => Byte( 0 )); 
      check : Byte_Array (1 .. 2) := (others => Byte( 0 ));
      cks : Fletcher16_Byte.Checksum_Type := (others => Byte( 0 ));
      type buffer_pointer_Type is mod HIL.UART.BUFFER_MAX;
      pointer : buffer_pointer_Type := 0;
   begin
      isValid := False;
      data := (others => Byte( 0 ) );  -- EXCEPTION: Bis hier
      
      HIL.UART.read(UBLOX_M8N, data_rx);
      for i in 1 .. data_rx'Length - 2 loop
         if data_rx(i) = UBX_SYNC1 and data_rx(i + 1) = UBX_SYNC2 then
            pointer := buffer_pointer_Type( i - 1 );
            
            head := data_rx(Integer(pointer + 3) .. Integer(pointer + 6));
            
            if head(3) = UBX_CLASS_NAV and head(4) = UBX_ID_NAV_PVT and head(5) = UBX_LENGTH_NAV_PVT then 
               
               if (pointer + 7) < (pointer + 100) then
                  message := data_rx(Integer(pointer + 7) .. Integer(pointer + 98));  -- EXCEPTION: mögliches 0 Array
                  check := data_rx(Integer(pointer + 99) .. Integer(pointer + 100));         
               end if;
            
               cks := Fletcher16_Byte.Checksum( head & message );
               if check(1) = cks.ck_a and check(2) = cks.ck_b then
                  Logger.log_console(Logger.TRACE, "UBX valid");
                  data := message;
                  if message(20) /= 0 then
                     isValid := True;
                  end if;
               else
                  data := (others => Byte( 0 ));
                  Logger.log_console(Logger.DEBUG, "UBX invalid");
               end if;
            
            elsif head(3) = UBX_CLASS_ACK and head(4) = UBX_ID_ACK_ACK and head(5) = UBX_LENGTH_ACK_ACK then
               Logger.log_console(Logger.TRACE, "UBX Ack");
            end if;             
            

            exit;
         end if;
      end loop;
         
         -- got class 1, id 3, length 16 -> NAV_STATUS
         Logger.log_console(Logger.TRACE, "UBX msg class " & Integer'Image(Integer(head(3))) & ", id "
                    & Integer'Image(Integer(head(4))));
   end readFromDevice;   


   procedure init is
      
      msg_cfg_prt_head : constant UBX_Header_Array := (1 => UBX_SYNC1,
                                              2 => UBX_SYNC2,
                                              3 => UBX_CLASS_CFG,
                                              4 => UBX_ID_CFG_PRT,
                                              5 => Byte(20),
                                              6 => Byte(0));
                                              
      msg_cfg_prt : Data_Type(0 .. 19) := (0 => UBX_TX_CFG_PRT_PORTID,
                                           2 => Byte(0),
                                           4 => HIL.toBytes( UBX_TX_CFG_PRT_MODE )(1), -- uart mode 8N1
                                           5 => HIL.toBytes( UBX_TX_CFG_PRT_MODE )(2), -- uart mode no parity, 1 stop bit
                                           8 => HIL.toBytes( HIL.Config.UBLOX_BAUD_RATE_HZ )(1),
                                           9 => HIL.toBytes( HIL.Config.UBLOX_BAUD_RATE_HZ )(2),
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
                                          2 => Byte( 10 ) );  -- rate in multiple of measurement rate: 2 => 2*1Hz
                                          
      msg_cfg_rate_head : UBX_Header_Array := (1 => UBX_SYNC1,
                                              2 => UBX_SYNC2,
                                              3 => UBX_CLASS_CFG,
                                              4 => UBX_ID_CFG_RATE,
                                              5 => Byte(3),  -- length
                                              6 => Byte(0));
                                          
      current_time : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      MESSAGE_DELAY_MS : constant Ada.Real_Time.Time_Span := Milliseconds( 10 );
      
      procedure delay_ms( ms : Natural) is
         current_time : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      begin
         delay until current_time + Ada.Real_Time.Milliseconds( ms );
      end delay_ms;
         
   begin
   
    
   
      for i in Integer range 1 .. 2 loop
      -- 1. Set binary protocol (CFG-PRT, own message)
      writeToDevice(msg_cfg_prt_head, msg_cfg_prt);  -- no ACK is expected here
      

      -- 2. Set baudrate (CFG-PRT, again own message)

      -- 3. Set message rates (CFG-MSG)
--        delay_ms( 10 );
--        msg_cfg_msg(2) := Byte( 5 );
--        msg_cfg_msg(1) := UBX_ID_NAV_PVT;
--        writeToDevice(msg_cfg_msg_head, msg_cfg_msg);  -- implemented for ubx7+ modules only
--        
      -- set other to 0
      msg_cfg_msg(2) := Byte( 0 );
      msg_cfg_msg(1) := UBX_ID_NAV_POSLLH;
      delay_ms( 10 );
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg);
            
      msg_cfg_msg(1) := UBX_ID_NAV_SOL;
      delay_ms( 10 );
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg);
      
      msg_cfg_msg(1) := UBX_ID_NAV_VELNED;
      delay_ms( 10 );
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg);  

      
      msg_cfg_msg(1) := UBX_ID_NAV_STATUS;
      delay_ms( 10 );
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg);
      delay_ms( 10 );
      
      -- set NAV_PVT to 0.2Hz
      msg_cfg_msg(2) := Byte( 5 );
      msg_cfg_msg(1) := UBX_ID_NAV_PVT;
      writeToDevice(msg_cfg_msg_head, msg_cfg_msg);  -- implemented for ubx7+ modules only
      delay_ms( 10 );    
      
      end loop;
      -- 4. set dynamic model
      
      
   end init;

   -- read measurements values. Should be called periodically.
   procedure update_val is
      data_rx : Data_Type(0 .. 91) := (others => 0);
      gpsmsg : ULog.Message (ULog.GPS);
      isValid : Boolean;
   begin
      readFromDevice(data_rx, isValid);
      if isValid then
         G_GPS_Message.year := Year_Type( HIL.toUnsigned_16( data_rx( 4 .. 5 ) ) );
         G_GPS_Message.month := Month_Type( data_rx( 6 ) );
         G_GPS_Message.lon := Unit_Type(Float( HIL.toInteger_32( data_rx(24 .. 27) ) ) * 1.0e-7) * Degree;
         G_GPS_Message.lat := Unit_Type(Float( HIL.toInteger_32( data_rx(28 .. 31) ) ) * 1.0e-7) * Degree;
         G_GPS_Message.alt := Unit_Type(Float( HIL.toInteger_32( data_rx(36 .. 39) ) )) * Milli * Meter;
         
         case data_rx(20) is
         when HIL.Byte(2) => G_GPS_Message.fix := FIX_2D;
         when HIL.Byte(3) => G_GPS_Message.fix := FIX_3D;
         when others => G_GPS_Message.fix := NO_FIX;
         end case;
         
         
         Logger.log_console(Logger.TRACE, "Long: " & AImage( G_GPS_Message.lon ) );
      else
         G_GPS_Message.fix := NO_FIX;
      end if;

      -- logging
      --gpsmsg.lon := G_position.Longitude;
      Logger.log_sd (level => Logger.SENSOR, message => gpsmsg);
   end update_val;


   function get_Position return GPS_Loacation_Type is
   begin
      return (G_GPS_Message.lon, G_GPS_Message.lat, G_GPS_Message.alt);
   end get_Position;
   
   function get_GPS_Message return GPS_Message_Type is
   begin
      return G_GPS_Message;
   end get_GPS_Message;
   
   function get_Fix return GPS_Fix_Type is
   begin
      return G_GPS_Message.fix;
   end get_Fix;

   function get_Direction return Heading_Type is
   begin
      return G_heading;
   end get_Direction;

   procedure perform_Self_Check (Status : out Error_Type) is
   begin
      null;
   end perform_Self_Check;





end ublox8.Driver;
