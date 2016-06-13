

with PX4IO.Protocol; use PX4IO.Protocol;
with Interfaces; use Interfaces;
with Ada.Real_Time; use Ada.Real_Time;
with CRC8;
with Logger;

package body PX4IO.Driver 
with SPARK_Mode
is

   G_Servo_Angle_Left  : Servo_Angle_Type := Angle_Type (0.0);
   G_Servo_Angle_Right : Servo_Angle_Type := Angle_Type (0.0);
  
   G_Motor_Speed : Motor_Speed_Type := Angular_Velocity_Type (0.0);
   
   
   procedure write(page : Page_Type; offset : Offset_Type; data : Data_Type) 
   is
      Data_TX : HIL.UART.Data_Type := (
                                       1 => HIL.Byte( PKT_CODE_WRITE + data'Length/2 ),
                                       2 => HIL.Byte( 0 ),
                                       3 => HIL.Byte( page ),
                                       4 => HIL.Byte( offset )
                                       ) & data;
      Data_RX : HIL.UART.Data_Type(1 ..4) := (others => 0);
      valid   : Boolean := False;
      retries : Natural range 0 .. 5 := 0;
   begin
   
      Transmit_Loop : loop
         Data_TX(2) := 0;
         Data_TX(2) := CRC8.calculateCRC8( Data_TX );         
         HIL.UART.write(HIL.UART.PX4IO, Data_TX);
         HIL.UART.read(HIL.UART.PX4IO, Data_RX);  -- read response
      
         valid := valid_Package( Data_RX ) and Data_RX(1) = PKT_CODE_SUCCESS;
         
         exit Transmit_Loop when valid or retries >= 3;
         retries := retries + 1;
      end loop Transmit_Loop;
      
      if retries >= 3 then
         Logger.log(Logger.WARN, "PX4IO write failed");
         null;
      end if;
      
   end write;
   
   procedure read(page : Page_Type; offset : Offset_Type; data : out Data_Type)
   with pre => data'Length mod 2 = 0
   is
      Data_TX : HIL.UART.Data_Type(1 .. (4+data'Length)) := (     -- maximum 68 (4 + 64), but is this necessary?
                                               1 => HIL.Byte( 1 ),
                                               2 => HIL.Byte( 0 ),
                                               3 => HIL.Byte(page),
                                               4 => HIL.Byte(offset),
                                               others => HIL.Byte( 0 )
                                               );
      Data_RX : HIL.UART.Data_Type(1 .. (4+data'Length)) := ( others => 0 );
      valid   : Boolean := False;
      retries : Natural range 0 .. 5 := 0;
   begin
   
      Transmit_Loop : loop
         Data_TX(2) := CRC8.calculateCRC8( Data_TX );
         HIL.UART.write(HIL.UART.PX4IO, Data_TX);
         HIL.UART.read(HIL.UART.PX4IO, Data_RX);
         
         valid := valid_Package( Data_RX );
         
         exit Transmit_Loop when valid or retries >= 3;
         retries := retries + 1;
      end loop Transmit_Loop;
      
      -- for pos in Data'Range loop
      data( data'Range ) := Data_RX(5 .. (4 + data'Length));
   end read;
   
   
   procedure modify_set(page : Page_Type; offset : Offset_Type; set_mask : HIL.Unsigned_16_Mask) is
      Data   : Data_Type(1 .. 2) := ( others => 0 );
      Status : Unsigned_16 := 0;
   begin
      read(page, offset, Data);
      Status := HIL.toUnsigned_16( Data );
      set_Bits(Status, set_mask);
      Data   := HIL.toBytes( Status );      
      write(page, offset, Data);
   end modify_set;
   
   procedure modify_clear(page : Page_Type; offset : Offset_Type; clear_mask : HIL.Unsigned_16_Mask) is
      Data   : Data_Type(1 .. 2) := ( others => 0 );
      Status : Unsigned_16 := 0;
   begin
      read(page, offset, Data);
      Status := HIL.toUnsigned_16( Data );
      clear_Bits(Status, clear_mask);
      Data   := HIL.toBytes( Status );      
      write(page, offset, Data);
   end modify_clear;  
   
   procedure handle_Error(msg : String) is
   begin
      Logger.log(Logger.ERROR, msg);
      null;
   end handle_Error;
   
   
   function valid_Package( data : in Data_Type ) return Boolean is 
      check_data : Data_Type := data;
   begin
      check_data(2) := 0;   -- reset crc field for calculation
      return CRC8.calculateCRC8( check_data ) = data(2);      
   end valid_Package;
   

   -- init
   procedure initialize is
      protocol : Data_Type(1 .. 2) := (others => 0);
      Data : Data_Type(1 .. 2) := (others => 0);       
   begin
      Logger.log(Logger.DEBUG, "Probe PX4IO");
      for i in Integer range 1 .. 3 loop
         read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_PROTOCOL_VERSION, protocol);
         if protocol(1) = 4 then
            Logger.log(Logger.DEBUG, "PX4IO alive");
            exit;
         elsif i = 3 then
            handle_Error("PX4IO: Wrong Protocol: " & HIL.Byte'Image( protocol(1) ) );
         end if;
      end loop;
    
      -- set debug level to 5
      write(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_SET_DEBUG, HIL.toBytes ( Unsigned_16(5) ) );
      --delay until Clock + Milliseconds ( 2 ); -- delay until or Clock makes SPARK conk out      

      -- clear all Alarms
      write(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_ALARMS, (1 .. 2 => HIL.Byte ( 255 ) ) );   -- PX4IO clears Bits with 1 (inverted)
      declare 
         -- SPARK RM 7.1.3: Clock() has side-effects, so it must
         -- be used in a "non-interfering context". That means, we have
         -- to make it a proper R-value here and cannot directly
         -- increment it with Milliseconds:
         t_abs : ada.Real_Time.Time := Clock;
      begin
         t_abs := t_abs + Milliseconds( 2 );
         delay until t_abs;
      end;
      
      -- clear status flags
      modify_clear(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_FLAGS, 
                   PX4IO_P_STATUS_FLAGS_FAILSAFE or 
                   PX4IO_P_STATUS_FLAGS_FMU_INITIALIZED );
                   
      -- set Mixer OK
      modify_set(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_FLAGS, 
                  PX4IO_P_STATUS_FLAGS_MIXER_OK or
                  PX4IO_P_STATUS_FLAGS_INIT_OK
                  );
                  
    
      -- disarm before setup (exactly as in original PX4 code)
      modify_clear(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, 
		PX4IO_P_SETUP_ARMING_FMU_ARMED or
		PX4IO_P_SETUP_ARMING_INAIR_RESTART_OK or
		PX4IO_P_SETUP_ARMING_MANUAL_OVERRIDE_OK or
		PX4IO_P_SETUP_ARMING_ALWAYS_PWM_ENABLE or
                PX4IO_P_SETUP_ARMING_FORCE_FAILSAFE or
                PX4IO_P_SETUP_ARMING_LOCKDOWN );
      --delay until Clock + Milliseconds ( 2 );
      
      
      -- read the setup
      read_Status;
    
      -- read some senseless values because original PX4 is doing it
--        read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_HARDWARE_VERSION, Data);
--        read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_ACTUATOR_COUNT, Data);
--        read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_CONTROL_COUNT, Data);
--        read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_RELAY_COUNT, Data);
--        read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_MAX_TRANSFER, Data);   -- substract -2 (because PX4 is doing it)
--        read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_RC_INPUT_COUNT, Data);
      --delay until Clock + Milliseconds ( 2 );
    
    
      -- set PWM limits
      --write(PX4IO_PAGE_CONTROL_MIN_PWM, 0, );
      --write(PX4IO_PAGE_CONTROL_MAX_PWM
      
      
      -- give IO some values (should enable PX4IO_P_STATUS_FLAGS_FMU_INITIALIZED )
      sync_Outputs;     
      
      
      
      -- disable RC (should cause PX4IO_P_STATUS_FLAGS_INIT_OK)
      --modify_set(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, PX4IO_P_SETUP_ARMING_RC_HANDLING_DISABLED); 
      --delay until Clock + Milliseconds ( 2 );


      -- setup arming
      modify_set(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, 
             PX4IO_P_SETUP_ARMING_IO_ARM_OK or  
             PX4IO_P_SETUP_ARMING_FMU_ARMED or
             --PX4IO_P_SETUP_ARMING_INAIR_RESTART_OK or
             --PX4IO_P_SETUP_ARMING_MANUAL_OVERRIDE_OK or
             PX4IO_P_SETUP_ARMING_RC_HANDLING_DISABLED --or  -- disable RC, 
             --PX4IO_P_SETUP_ARMING_ALWAYS_PWM_ENABLE 
         );

      -- FMU armed
      --modify_set(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, PX4IO_P_SETUP_ARMING_FMU_ARMED);
      
      -- RC off
      --modify_set(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, PX4IO_P_SETUP_ARMING_RC_HANDLING_DISABLED);
      
      

      -- safety off
      write(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_FORCE_SAFETY_OFF, HIL.toBytes (PX4IO_FORCE_SAFETY_MAGIC ) ); -- force into armed state

   end initialize;
   
   
   procedure read_Status is
      Status : Data_Type(1 .. 2) := (others => 0);
   begin
      read(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_FLAGS, Status);
      Logger.log(Logger.DEBUG, "PX4IO Status: " & 
                 Integer'Image( Integer(Status(2)) ) & ", " & Integer'Image( Integer(Status(1)) ) );
      
      read(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_ALARMS, Status);
      Logger.log(Logger.DEBUG, "PX4IO Alarms: " & Integer'Image( Integer(Status(2)) ) & ", " & Integer'Image( Integer(Status(1)) ) );    
      
      read(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, Status);
      Logger.log(Logger.DEBUG, "PX4IO ArmSetup: " & Integer'Image( Integer(Status(2)) ) & ", " & Integer'Image( Integer(Status(1)) ) );          
      
   end read_Status;


   procedure set_Servo_Angle(servo : Servo_Type; angle : Servo_Angle_Type) is
   begin
      case(servo) is
            when LEFT_ELEVON  => G_Servo_Angle_Left  := angle;
            when RIGHT_ELEVON => G_Servo_Angle_Right := angle;
      end case;
      Logger.log(Logger.DEBUG, "Servo Angle set");
   end set_Servo_Angle;
   
   
   procedure set_Motor_Speed( speed : Motor_Speed_Type ) is
   begin
         G_Motor_Speed := speed;  
   end set_Motor_Speed;
   
   
   
   
   function servo_Duty_Cycle(angle : in Servo_Angle_Type) return Unsigned_16 
   with post => servo_Duty_Cycle'Result >= 1_000 and servo_Duty_Cycle'Result <= 2_000
   is
      -- modulo : Angle_Type := Angle_Type'Remainder(angle, SERVO_ANGLE_MAX_LIMIT + 1.0);
   begin
      return 1_000 + Unsigned_16( angle / SERVO_ANGLE_MAX_LIMIT * 1000.0);
   end servo_Duty_Cycle;
   
   
   function esc_PWM(speed : in Motor_Speed_Type) return Unsigned_16
   is
   begin
      return Unsigned_16(speed); -- Todo
   end esc_PWM;
   

   procedure arm is
   begin
      write(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_FORCE_SAFETY_OFF, HIL.toBytes( PX4IO_FORCE_SAFETY_MAGIC ) );
   end arm;
   
   procedure disarm is
   begin
      -- this cast is required to remove the constant; otherwise SPARK flow analyss fails
      write(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_FORCE_SAFETY_ON, HIL.toBytes ( PX4IO_FORCE_SAFETY_MAGIC ) );
   end disarm;  
   
   
   
   
   procedure sync_Outputs is
            Duty_Cycle : Data_Type (1 .. 2);
            Speed      : Data_Type (1 .. 16) := (others => 0);   -- 8 Controls;
            Status     : Data_Type(1 .. 2) := (others => 0);
   begin
      -- left
      Duty_Cycle := HIL.toBytes( servo_Duty_Cycle( G_Servo_Angle_Left ) ); 
      write(PX4IO_PAGE_DIRECT_PWM, 0, Duty_Cycle);
      
      -- right
      Duty_Cycle := HIL.toBytes( servo_Duty_Cycle( G_Servo_Angle_Right ) ); 
      write(PX4IO_PAGE_DIRECT_PWM, 1, Duty_Cycle);
      
      -- motor
      Speed(1 .. 2) := HIL.toBytes( esc_PWM( G_Motor_Speed ) );
      --write(PX4IO_PAGE_CONTROLS, PX4IO_P_CONTROLS_GROUP_0, Speed);  -- write to CONTROLS clears PX4IO_PAGE_DIRECT_PWM
      write(PX4IO_PAGE_DIRECT_PWM, 2, Speed);
      
      -- check state
      read(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_FLAGS, Status);
      if HIL.isSet( HIL.toUnsigned_16( Status ), PX4IO_P_STATUS_FLAGS_FAILSAFE ) then
         Logger.log(Logger.WARN, "Failsafe");
         null;
      else
         Logger.log(Logger.DEBUG, ".");
         null;
      end if;
      
   end sync_Outputs;
   


end PX4IO.Driver;
