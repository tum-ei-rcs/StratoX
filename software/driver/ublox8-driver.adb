
with Units; use Units;

with Fletcher16;
with HIL; use HIL;
with HIL.Config; use HIL.Config;
with HIL.Devices;

with Interfaces; use Interfaces;
--with Bounded_Image; use Bounded_Image;

with Logger;

with ublox8.Protocol; use ublox8.Protocol;
with Ada.Real_Time; use Ada.Real_Time;

package body ublox8.Driver with
SPARK_Mode,
Refined_State => (State => (G_GPS_Message, last_msg_time))
is  
   package Fletcher16_Byte is new Fletcher16 (Index_Type => Natural, 
                                              Element_Type => Byte, 
                                              Array_Type => Byte_Array);
   

   G_heading : constant Heading_Type := NORTH;
   last_msg_time : Ada.Real_Time.Time := Ada.Real_Time.Time_Last;
   
   G_GPS_Message : GPS_Message_Type := 
     (  itow => 0,
        datetime => (year => Year_Type'First,
                     mon => Month_Type'First,
                     day => Day_Of_Month_Type'First,
                     hour => Hour_Type'First,
                     min => Minute_Type'First,
                     sec => Second_Type'First                     
                    ),
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
      n_read : Natural := 0;
   begin
      while now < start + timeout and then (n_read = 0 or sync(1) /= UBX_SYNC1) loop
         HIL.UART.read(UBLOX_M8N, sync(1 .. 1), n_read);
         now := Ada.Real_Time.Clock;
      end loop;
      HIL.UART.read(UBLOX_M8N, sync(2 .. 2), n_read);
      
      if n_read > 0 and sync(1) = UBX_SYNC1 and sync(2) = UBX_SYNC2 then
         isReceived := True;
      else 
         isReceived := False;
      end if;
   end waitForSync;

   procedure waitForAck(isReceived : out Boolean) is
      head : Byte_Array (3 .. 6) := (others => Byte( 0 ));
      n_read : Natural;
   begin
      waitForSync(isReceived);
      if isReceived then
         HIL.UART.read(UBLOX_M8N, head, n_read);
         if n_read = head'Length then 
            if head(3) = UBX_CLASS_ACK and head(4) = UBX_ID_ACK_ACK and head(5) = UBX_LENGTH_ACK_ACK then
               Logger.log_console(Logger.DEBUG, "UBX Ack");
            elsif head(3) = UBX_CLASS_ACK and head(4) = UBX_ID_ACK_NAK and head(5) = UBX_LENGTH_ACK_ACK then
               Logger.log_console(Logger.DEBUG, "UBX NAK");
               isReceived := False;
            end if;
         end if;
      end if;
   end waitForAck;

   procedure writeToDevice(header: UBX_Header_Array; data : Data_Type) 
     with Pre => data'Length <= Natural'Last - 4 - header'Length;
   
   procedure writeToDevice(header: UBX_Header_Array; data : Data_Type) is      
      cks : constant Fletcher16_Byte.Checksum_Type := Fletcher16_Byte.Checksum( header(3 .. 6) & data );
      check : constant UBX_Checksum_Array := (1 => cks.ck_a, 2 => cks.ck_b);
      isReceived : Boolean := False;
      retries : Natural := 1;
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      while isReceived = False and retries > 0 loop
         HIL.UART.write(UBLOX_M8N, header & data & check);
         delay until now + Milliseconds(2);
         waitForAck(isReceived);
         retries := retries - 1;
      end loop;
      if retries = 0 then
         Logger.log_console(Logger.DEBUG, "UBX write Timeout");
      end if;
   end writeToDevice;

   subtype UBX_Data is Data_Type (0 .. 91);
   type Buffer_Wrap_Idx is mod HIL.UART.BUFFER_MAX;
   
   procedure readFromDevice(data : out UBX_Data; isValid : out Boolean);
   
   --  FIXME: this is unsynchronized. It reads as much as it can, and then tries to find one message
   --  if no message, then it discards all. If message found, then remainder is also discarded
   procedure readFromDevice(data : out UBX_Data; isValid : out Boolean) is
      ubxhead : Byte_Array (3 .. 6);
      data_rx : Byte_Array (0 .. HIL.UART.BUFFER_MAX - 1);
      message : Byte_Array (0 .. 91) := (others => Byte( 0 )); 
      check   : Byte_Array (1 .. 2) := (others => Byte( 0 ));
      cks           : Fletcher16_Byte.Checksum_Type;
      msg_start_idx : Buffer_Wrap_Idx;
      n_read        : Natural;
   begin
      isValid := False;
      data := (others => Byte( 0 ) );
      
      HIL.UART.read(UBLOX_M8N, data_rx, n_read);
      if n_read > 0 then
         for i in 0 .. data_rx'Length - 2 loop -- scan for message. FIXME: why start at one?
            if data_rx (i) = UBX_SYNC1 and data_rx (i + 1) = UBX_SYNC2 then
               declare
                  now : constant Ada.Real_Time.Time := Clock;
               begin
                  last_msg_time := now;
               end;               

               msg_start_idx := Buffer_Wrap_Idx (i);
               
               --  get header (bytes 3 .. 6)
               declare
                  idx_start : constant Buffer_Wrap_Idx := msg_start_idx + 2;
                  idx_end   : constant Buffer_Wrap_Idx := msg_start_idx + 5;
                  pragma Assert (idx_start + 3 = idx_end); -- modulo works as expected
               begin
                  if idx_start > idx_end then
                     -- wrap
                     ubxhead := data_rx (Integer (idx_start) .. data_rx'Last) 
                       & data_rx (data_rx'First .. Integer (idx_end));
                  else                     
                     -- no wrap
                     ubxhead := data_rx (Integer (idx_start) .. Integer (idx_end));
                  end if;
               end;
            
               if ubxhead (3) = UBX_CLASS_NAV and 
               then ubxhead (4) = UBX_ID_NAV_PVT and 
               then ubxhead (5) = UBX_LENGTH_NAV_PVT 
               then 
               
                  --  copy message
                  declare
                     idx_datastart : constant Buffer_Wrap_Idx := msg_start_idx + 6;                     
                     idx_dataend   : constant Buffer_Wrap_Idx := msg_start_idx + 97;                     
                     idx_crcstart  : constant Buffer_Wrap_Idx := msg_start_idx + 98;
                     idx_crcend    : constant Buffer_Wrap_Idx := msg_start_idx + 99;
                  begin
                     if idx_datastart < idx_crcend then
                        -- no wrap
                        message := data_rx (Integer (idx_datastart) .. Integer (idx_dataend)); 
                        check := data_rx (Integer (idx_crcstart) .. Integer (idx_crcend));         
                     else
                        null; -- TODO: implement wrap
                     end if;
                  end;
            
                  --  checksum the message
                  cks := Fletcher16_Byte.Checksum (ubxhead & message);
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
            
               elsif ubxhead (3) = UBX_CLASS_ACK and
               then ubxhead (4) = UBX_ID_ACK_ACK and 
               then ubxhead (5) = UBX_LENGTH_ACK_ACK 
               then
                  Logger.log_console(Logger.TRACE, "UBX Ack");
               end if;             
            
               exit;            
            end if;
         end loop;
         -- got class 1, id 3, length 16 -> NAV_STATUS
         --  Logger.log_console(Logger.TRACE, "UBX msg class " & Integer_Img (Integer (ubxhead (3))) & ", id "
         --     & Integer_Img (Integer (ubxhead (4))));
      else
         -- no data
         isValid := False;
      end if;         
      
   end readFromDevice;   


   procedure init is
      
      msg_cfg_prt_head : constant UBX_Header_Array := (1 => UBX_SYNC1,
                                              2 => UBX_SYNC2,
                                              3 => UBX_CLASS_CFG,
                                              4 => UBX_ID_CFG_PRT,
                                              5 => Byte(20),
                                              6 => Byte(0));
                                              
      msg_cfg_prt : constant Data_Type(0 .. 19) := (0 => UBX_TX_CFG_PRT_PORTID,
                                           2 => Byte(0),
                                           4 => HIL.toBytes( UBX_TX_CFG_PRT_MODE )(1), -- uart mode 8N1
                                           5 => HIL.toBytes( UBX_TX_CFG_PRT_MODE )(2), -- uart mode no parity, 1 stop bit
                                           8 => HIL.toBytes( HIL.Config.UBLOX_BAUD_RATE_HZ )(1),
                                           9 => HIL.toBytes( HIL.Config.UBLOX_BAUD_RATE_HZ )(2),
                                           12 => Byte( 1 ),  -- ubx protocol
                                           14 => Byte( 1 ),  -- ubx protocol
                                           16 => Byte( 0 ), -- flags
                                           others => Byte( 0 ) );
                                      
      msg_cfg_msg_head : constant UBX_Header_Array := (1 => UBX_SYNC1,
                                              2 => UBX_SYNC2,
                                              3 => UBX_CLASS_CFG,
                                              4 => UBX_ID_CFG_MSG,
                                              5 => Byte(3),  -- length
                                              6 => Byte(0));
                                              
      msg_cfg_msg : Data_Type(0 .. 2) := (0 => UBX_CLASS_NAV,
                                          1 => UBX_ID_NAV_PVT,
                                          2 => Byte( 10 ) );  -- rate in multiple of measurement rate: 2 => 2*1Hz
                                          
--        msg_cfg_rate_head : UBX_Header_Array := (1 => UBX_SYNC1,
--                                                 2 => UBX_SYNC2,
--                                                 3 => UBX_CLASS_CFG,
--                                                 4 => UBX_ID_CFG_RATE,
--                                                 5 => Byte(3),  -- length
--                                                 6 => Byte(0));
                                          
      current_time : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      pragma Unreferenced (current_time);
      MESSAGE_DELAY_MS : constant Ada.Real_Time.Time_Span := Milliseconds( 10 );
      pragma Unreferenced (MESSAGE_DELAY_MS);
      
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
      
      -- limit NAV_PVT rate to every second time (=0.5Hz)
         msg_cfg_msg(2) := Byte( 2 );
         msg_cfg_msg(1) := UBX_ID_NAV_PVT;
         writeToDevice(msg_cfg_msg_head, msg_cfg_msg);  -- implemented for ubx7+ modules only
         delay_ms( 10 );    
      
      end loop;
      -- 4. set dynamic model
      
      
   end init;

   --  read measurements values. Should be called periodically.
   --  Parses Ublox message UBX-NAV-PVT
   --  FIXME: declare packed record and use Unchecked_Union or use Unchecked_Conversion
   procedure update_val is
      data_rx : UBX_Data := (others => 0);
      isValid : Boolean;
      --  these look weird below, but they avoid that too large values coming from 
      --  the GPS device multiplied by degree & co. get out of range:
      function Sat_Cast_Lat is new Units.Saturated_Cast (Latitude_Type);
      function Sat_Cast_Lon is new Units.Saturated_Cast (Longitude_Type);
      function Sat_Cast_Alt is new Units.Saturated_Cast (Altitude_Type);
   begin
      readFromDevice (data_rx, isValid);
      if isValid then
         G_GPS_Message.itow := GPS_Time_Of_Week_Type (HIL.toUnsigned_32 (data_rx (0 .. 3)));
         G_GPS_Message.datetime.year := Year_Type (HIL.toUnsigned_16 (data_rx (4 .. 5)));
         G_GPS_Message.datetime.mon := (if Integer (data_rx (6)) in Month_Type then Month_Type (data_rx (6)) else Month_Type'First);
         G_GPS_Message.datetime.day := (if Integer (data_rx (7)) in Day_Of_Month_Type then Day_Of_Month_Type (data_rx (7)) else Day_Of_Month_Type'First);
         G_GPS_Message.datetime.hour := (if Integer (data_rx (8)) in Integer (Hour_Type'First) .. Integer (Hour_Type'Last) then Hour_Type (data_rx (8)) else Hour_Type'First);
         G_GPS_Message.datetime.min := (if Integer (data_rx (9)) in Integer (Minute_Type'First) .. Integer (Minute_Type'Last) then Minute_Type (data_rx (9)) else Minute_Type'First);
         G_GPS_Message.datetime.sec := (if Integer (data_rx (10)) in Integer (Second_Type'First) .. Integer (Second_Type'Last) then Second_Type (data_rx (10)) else Second_Type'First);

         G_GPS_Message.lon := Sat_Cast_Lon (Float (HIL.toInteger_32 (data_rx (24 .. 27))) * 1.0e-7 * Float (Degree));
         G_GPS_Message.lat := Sat_Cast_Lat (Float (HIL.toInteger_32 (data_rx (28 .. 31))) * 1.0e-7 * Float (Degree));
         G_GPS_Message.alt := Sat_Cast_Alt (Float (HIL.toInteger_32 (data_rx (36 .. 39))) * Float (Milli * Meter));
         G_GPS_Message.sats := Unsigned_8 (data_rx (23));
         declare
            i32_speed : constant Integer_32 := HIL.toInteger_32 (data_rx (60 .. 63));
            pragma Annotate (GNATprove, False_Positive, "precondition might fail", "pre of toInteger_32 is valid");
         begin            
            G_GPS_Message.speed := Units.Linear_Velocity_Type (Float (i32_speed) / 1000.0);
         end;
         
         
         case data_rx(20) is
         when HIL.Byte(2) => G_GPS_Message.fix := FIX_2D;
         when HIL.Byte(3) => G_GPS_Message.fix := FIX_3D;
         when others => G_GPS_Message.fix := NO_FIX;
         end case;
         
         --Logger.log_console (Logger.DEBUG, "Sats: " & Unsigned_8'Image (G_GPS_Message.sats));
         --Logger.log_console(Logger.TRACE, "Long: " & AImage( G_GPS_Message.lon ) );
      else
         G_GPS_Message.fix := NO_FIX;
      end if;

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
   
   function get_Velo return Linear_Velocity_Type is
   begin
      return G_GPS_Message.speed;
   end get_Velo;
   
   function get_Time return GPS_DateTime_Type is
   begin
      return G_GPS_Message.datetime;
   end get_Time;
   
   function get_Nsat return Unsigned_8 is
   begin
      return G_GPS_Message.sats;
   end get_Nsat;

   function get_Direction return Heading_Type is
   begin
      return G_heading;
   end get_Direction;
   pragma Unreferenced (get_Direction);

   --  Self Check: wait until we see valid GPS messages (not necessarily a FIX)
   procedure perform_Self_Check (Status : out Error_Type) is
      now     :  Ada.Real_Time.Time := Clock;
      timeout : constant Ada.Real_Time.Time := now + Seconds (30);      
   begin
      Status := FAILURE;
      
      Wait_Message_Loop:
      while now < timeout loop
         update_val;

         now := Clock;
         
         if last_msg_time <= now then
            declare
               msg_age : constant Ada.Real_Time.Time_Span := now - last_msg_time;
            begin
               if msg_age < Seconds (1) then
                  Status := SUCCESS;
                  exit Wait_Message_Loop;
               end if;
            end;
         end if;
      end loop Wait_Message_Loop;
           
   end perform_Self_Check;

end ublox8.Driver;
