
with HIL.UART; use type HIL.UART.Data_Type;
with PX4IO.Protocol; use PX4IO.Protocol;
with HIL; 
with Interfaces; use Interfaces;
with CRC8;
with Logger;


package body PX4IO.Driver is

   
   subtype Page_Type is HIL.Byte;
   subtype Offset_Type is HIL.Byte;
   
   subtype Data_Type is HIL.UART.Data_Type;
   
   
   G_Servo_Angle_Left  : Servo_Angle_Type := Angle_Type (0);
   G_Servo_Angle_Right : Servo_Angle_Type := Angle_Type (0);
   
   
   procedure write(page : Page_Type; offset : Offset_Type; data : Data_Type) is
      Data_TX : HIL.UART.Data_Type := (
                                       1 => HIL.Byte( PKT_CODE_WRITE + data'Length ),
                                       2 => HIL.Byte( 0 ),
                                       3 => HIL.Byte( page ),
                                       4 => HIL.Byte( offset )
                                       ) & data;
   begin
      HIL.UART.write(HIL.UART.PX4IO, Data_TX);
   end write;
   
   procedure read(page : Page_Type; offset : Offset_Type; data : out Data_Type)
   with pre => data'Length / 2 = 0
   is
      Data_TX : HIL.UART.Data_Type(1 .. (4+data'Length)) := (     -- maximum 68 (4 + 64), but is this necessary?
                                               1 => HIL.Byte( 1 ),
                                               2 => HIL.Byte( 0 ),
                                               3 => HIL.Byte(page),
                                               4 => HIL.Byte(offset),
                                               others => HIL.Byte( 0 )
                                               );
      Data_RX : HIL.UART.Data_Type(1 .. (4+data'Length)) := ( others => 0 );
   begin
      Data_TX(2) := CRC8.calculateCRC8( Data_TX );
      HIL.UART.write(HIL.UART.PX4IO, Data_TX);
      HIL.UART.read(HIL.UART.PX4IO, Data_RX);
      
     -- for pos in Data'Range loop
     data( Data'Range ) := Data_RX(5 .. (4 + Data'Length));
   end read;
   
   
   procedure handle_Error(msg : String) is
   begin
      Logger.log(Logger.ERROR, msg);
   end handle_Error;
   

   -- init
   procedure initialize is
      protocol : Data_Type(1 .. 2) := (others => 0);
   begin
      Logger.log(Logger.DEBUG, "Probe PX4IO");
      for i in Integer range 1 .. 3 loop
         read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_PROTOCOL_VERSION, protocol);
         if protocol(1) = 4 then 
            exit;
         elsif i = 3 then
            handle_Error("PX4IO: Wrong Protocol: " & HIL.Byte'Image( protocol(1) ) );
         end if;
      end loop;
        
      -- disarm
      write(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, 
            (1 => HIL.Byte (
             PX4IO_P_SETUP_ARMING_FMU_ARMED and 
             PX4IO_P_SETUP_ARMING_INAIR_RESTART_OK and
             PX4IO_P_SETUP_ARMING_MANUAL_OVERRIDE_OK and
             PX4IO_P_SETUP_ARMING_RC_HANDLING_DISABLED and
             PX4IO_P_SETUP_ARMING_ALWAYS_PWM_ENABLE and
             PX4IO_P_SETUP_ARMING_LOCKDOWN) ) );
        
      -- safety off
      write(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_FORCE_SAFETY_OFF, HIL.toBytes( PX4IO_FORCE_SAFETY_MAGIC ) );
        
        
      -- set PWM limits
      --write(PX4IO_PAGE_CONTROL_MIN_PWM, 0, );
      --write(PX4IO_PAGE_CONTROL_MAX_PWM
        
   end initialize;
   
   
   procedure read_Status is
      Status : Data_Type(1 .. 2) := (others => 0);
   begin
      read(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_FLAGS, Status);
      Logger.log(Logger.DEBUG, "PX4IO Status: " & Integer'Image( Integer(Status(2)) ) & ", " & Integer'Image( Integer(Status(1)) ) );
   end read_Status;


   procedure set_Servo_Angle(servo : Servo_Type; angle : Servo_Angle_Type) is
   begin
      case(servo) is
            when LEFT_ELEVON  => G_Servo_Angle_Left  := angle;
            when RIGHT_ELEVON => G_Servo_Angle_Right := angle;
      end case;
   end set_Servo_Angle;
   
   procedure sync_Outputs is
            Duty_Cycle : Data_Type (1 .. 2);
   begin
            -- left
           Duty_Cycle := HIL.toBytes( Unsigned_16( G_Servo_Angle_Left ) ); 
      --write(PX4IO_PAGE_SERVOS, 0, )
   end sync_Outputs;

end PX4IO.Driver;
