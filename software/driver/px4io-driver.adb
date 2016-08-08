

with PX4IO.Protocol; use PX4IO.Protocol;
with Ada.Real_Time; use Ada.Real_Time;
with CRC8;
with Logger;
with HIL.Devices;

with Profiler;

package body PX4IO.Driver 
with SPARK_Mode => Off -- fix bug in set_servo_angle() first (dimension mismatch)
is
   type Check_Status_Mod_Type is mod 2**5;
   G_check_counter : Check_Status_Mod_Type := 0;

   type State_Type is record
      Left_Servo_Offset  : Servo_Angle_Type := CFG_LEFT_SERVO_OFFSET;
      Right_Servo_Offset : Servo_Angle_Type := CFG_RIGHT_SERVO_OFFSET;
   end record;
   


   G_Servo_Angle_Left  : Servo_Angle_Type := Angle_Type (0.0);
   G_Servo_Angle_Right : Servo_Angle_Type := Angle_Type (0.0);
  
   G_Motor_Speed : Motor_Speed_Type := Angular_Velocity_Type (0.0);
   
   G_state : State_Type;
   
   
   procedure write(page : Page_Type; offset : Offset_Type; data : Data_Type; retries : in Natural := 2) 
   is
      Data_TX : HIL.UART.Data_Type := (
                                       1 => HIL.Byte( PKT_CODE_WRITE + data'Length/2 ),
                                       2 => HIL.Byte( 0 ),
                                       3 => HIL.Byte( page ),
                                       4 => HIL.Byte( offset )
                                       ) & data;
      Data_RX : HIL.UART.Data_Type(1 ..4) := (others => 0);
      valid   : Boolean := False;
      curr_retry : Natural := 0;
   begin
   
      Transmit_Loop : loop
         Data_TX(2) := 0;
         Data_TX(2) := CRC8.calculateCRC8( Data_TX );         
         HIL.UART.write(HIL.Devices.PX4IO, Data_TX);
         HIL.UART.read(HIL.Devices.PX4IO, Data_RX);  -- read response
      
         valid := valid_Package( Data_RX ) and Data_RX(1) = PKT_CODE_SUCCESS;
         
         exit Transmit_Loop when valid or curr_retry >= retries;
         curr_retry := curr_retry + 1;
      end loop Transmit_Loop;
      
      if curr_retry >= retries then
         Logger.log_console(Logger.WARN, "PX4IO write failed");
      end if;
      
   end write;
   
   procedure read(page : Page_Type; offset : Offset_Type; data : out Data_Type; retries : in Natural := 2)
   with pre => data'Length mod 2 = 0 and data'Length > 0
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
      curr_retry : Natural := 0;
      
      
      procedure delay_us( us : Natural ) is
         t_abs : Ada.Real_Time.Time := Clock;
      begin
         t_abs := t_abs + Microseconds( us );
         delay until t_abs;
      end;
   begin
   
      Transmit_Loop : loop
         Data_TX(2) := CRC8.calculateCRC8( Data_TX );
         HIL.UART.write(HIL.Devices.PX4IO, Data_TX);
         HIL.UART.read(HIL.Devices.PX4IO, Data_RX);
         
         valid := valid_Package( Data_RX );
         
         exit Transmit_Loop when valid or curr_retry >= retries;
         curr_retry := curr_retry + 1;
         delay_us( 100 );
      end loop Transmit_Loop;

      -- for pos in Data'Range loop
      data( data'Range ) := Data_RX(5 .. (4 + data'Length));

      if curr_retry >= retries then
         Logger.log_console(Logger.WARN, "PX4IO read failed");
         data( data'Range ) := (others => HIL.Byte( 0 ) );
      end if;
   end read;
   
   
   procedure modify_set(page : Page_Type; offset : Offset_Type; set_mask : HIL.Unsigned_16_Mask) is
      Data   : Data_Type(1 .. 2) := ( others => 0 );
      Status : Unsigned_16 := 0;
   begin
      read(page, offset, Data, 10);
      Status := HIL.toUnsigned_16( Data );
      set_Bits(Status, set_mask);
      Data   := HIL.toBytes( Status );      
      write(page, offset, Data);
   end modify_set;
   
   procedure modify_clear(page : Page_Type; offset : Offset_Type; clear_mask : HIL.Unsigned_16_Mask) is
      Data   : Data_Type(1 .. 2) := ( others => 0 );
      Status : Unsigned_16 := 0;
   begin
      read(page, offset, Data, 10);
      Status := HIL.toUnsigned_16( Data );
      clear_Bits(Status, clear_mask);
      Data   := HIL.toBytes( Status );      
      write(page, offset, Data);
   end modify_clear;  
   
   procedure handle_Error(msg : String) is
   begin
      Logger.log_console(Logger.ERROR, msg);
      null;
   end handle_Error;
   
   
   function valid_Package( data : in Data_Type ) return Boolean is 
      check_data : Data_Type := data;
   begin
      check_data(2) := 0;   -- reset crc field for calculation
      return CRC8.calculateCRC8( check_data ) = data(2);      -- SPARK: index check might fail
   end valid_Package;
   

   -- init
   procedure initialize is
      protocol_version : Data_Type(1 .. 2) := (others => 0); 
      
      
      procedure delay_us( us : NAtural ) is
         -- SPARK RM 7.1.3: Clock() has side-effects, so it must
         -- be used in a "non-interfering context". That means, we have
         -- to make it a proper R-value here and cannot directly
         -- increment it with Milliseconds:
         t_abs : Ada.Real_Time.Time := Clock;
      begin
         t_abs := t_abs + Microseconds( us );
         delay until t_abs;
      end;
      
      delay_profiler : Profiler.Profile_Tag;
      
   begin
      Logger.log_console(Logger.DEBUG, "Probe PX4IO");
      for i in Integer range 1 .. 3 loop
         read(PX4IO_PAGE_CONFIG, PX4IO_P_CONFIG_PROTOCOL_VERSION, protocol_version);
         if protocol_version(1) = 4 then
            Logger.log_console(Logger.DEBUG, "PX4IO alive");
            exit;
         elsif i = 3 then
            handle_Error("PX4IO: Wrong Protocol: " & HIL.Byte'Image( protocol_version(1) ) );
         end if;
      end loop;
    
      -- set debug level to 5
      write(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_SET_DEBUG, HIL.toBytes ( Unsigned_16(5) ) );
      --delay until Clock + Milliseconds ( 2 ); -- delay until or Clock makes SPARK conk out      



      -- safety on (for config after reboot)
      write(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_FORCE_SAFETY_ON, HIL.toBytes (PX4IO_FORCE_SAFETY_MAGIC ) ); -- force into armed state


      -- clear all Alarms
      write(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_ALARMS, (1 .. 2 => HIL.Byte ( 255 ) ) );   -- PX4IO clears Bits with 1 (inverted)
      
      delay_profiler.init("DelayProf");
      delay_profiler.start;
      
      
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
                PX4IO_P_SETUP_ARMING_FAILSAFE_CUSTOM or -- was 1 if failsafe
		PX4IO_P_SETUP_ARMING_INAIR_RESTART_OK or
		PX4IO_P_SETUP_ARMING_MANUAL_OVERRIDE_OK or
		PX4IO_P_SETUP_ARMING_ALWAYS_PWM_ENABLE or
                PX4IO_P_SETUP_ARMING_FORCE_FAILSAFE or
                PX4IO_P_SETUP_ARMING_TERMINATION_FAILSAFE or -- was 1 during failsafe
                PX4IO_P_SETUP_ARMING_LOCKDOWN );
      --delay until Clock + Milliseconds ( 2 );
      
      -- clear termination and failsafe twice, because px4io requires two steps for clearing both
--        modify_clear(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, 
--                     PX4IO_P_SETUP_ARMING_FORCE_FAILSAFE or
--                     PX4IO_P_SETUP_ARMING_TERMINATION_FAILSAFE );
--        
      
      -- disable RC (should cause PX4IO_P_STATUS_FLAGS_INIT_OK)
      modify_set(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, PX4IO_P_SETUP_ARMING_RC_HANDLING_DISABLED);       
      
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


      delay_profiler.stop;

      -- give IO some values (should enable PX4IO_P_STATUS_FLAGS_FMU_INITIALIZED )
      sync_Outputs;

      delay_profiler.log;

   end initialize;
   
   
   procedure read_Status is
      Status : Data_Type(1 .. 2) := (others => 0);
   begin
      read(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_FLAGS, Status);
      Logger.log_console(Logger.DEBUG, "PX4IO Status: " & 
                 Integer'Image( Integer(Status(2)) ) & ", " & Integer'Image( Integer(Status(1)) ) );
      
      read(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_ALARMS, Status);
      Logger.log_console(Logger.DEBUG, "PX4IO Alarms: " & Integer'Image( Integer(Status(2)) ) & ", " & Integer'Image( Integer(Status(1)) ) );    
      
      read(PX4IO_PAGE_SETUP, PX4IO_P_SETUP_ARMING, Status);
      Logger.log_console(Logger.DEBUG, "PX4IO ArmSetup: " & Integer'Image( Integer(Status(2)) ) & ", " & Integer'Image( Integer(Status(1)) ) );          
      
   end read_Status;


   procedure set_Servo_Angle(servo : Servo_Type; angle : Servo_Angle_Type) is
      function saturate( angle : Angle_Type ) return Servo_Angle_Type is
         result : Servo_Angle_Type := 0.0 * Degree;
      begin
         if angle > Servo_Angle_Type'Last then
            result := Servo_Angle_Type'Last;
         elsif angle < Servo_Angle_Type'First then
            result := Servo_Angle_Type'First;
         else
            result := angle;
         end if;
         return result;
      end saturate;
   begin
      case(servo) is
         --  TODO: bug? Servo_Angle_Type is casted to Angle_Type, but latter one is in radians, servo angle in degree.
            when LEFT_ELEVON  => G_Servo_Angle_Left  := saturate( Angle_Type(angle) - Angle_Type(G_state.Left_Servo_Offset) );
            when RIGHT_ELEVON => G_Servo_Angle_Right := saturate( Angle_Type(angle) - Angle_Type(G_state.Right_Servo_Offset) );
      end case;
      Logger.log_console(Logger.TRACE, "Servo Angle " & AImage(angle) );
   end set_Servo_Angle;
   
   
   procedure set_Motor_Speed( speed : Motor_Speed_Type ) is
   begin
         G_Motor_Speed := speed;  
   end set_Motor_Speed;
   
   
   
   
   function servo_Duty_Cycle(angle : in Servo_Angle_Type) return Unsigned_16 
   with post => servo_Duty_Cycle'Result >= 1_000 and servo_Duty_Cycle'Result <= 2_000
   is
      pulse_range : constant Unit_Type := Unit_Type( SERVO_PULSE_LENGTH_LIMIT_MAX - SERVO_PULSE_LENGTH_LIMIT_MIN);
   begin
      return SERVO_PULSE_LENGTH_LIMIT_MIN + Unsigned_16( (angle - Servo_Angle_Type'First) / 
                                                         (Servo_Angle_Type'Last - Servo_Angle_Type'First) * pulse_range );
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
      Duty_Cycle := HIL.toBytes( servo_Duty_Cycle( - G_Servo_Angle_Right ) );  -- Minus because Servo is flipped
      write(PX4IO_PAGE_DIRECT_PWM, 1, Duty_Cycle);
      
      -- motor
      Speed(1 .. 2) := HIL.toBytes( esc_PWM( G_Motor_Speed ) );
      --write(PX4IO_PAGE_CONTROLS, PX4IO_P_CONTROLS_GROUP_0, Speed);  -- write to CONTROLS clears PX4IO_PAGE_DIRECT_PWM
      write(PX4IO_PAGE_DIRECT_PWM, 2, Speed);
      
      -- check state
      G_check_counter := Check_Status_Mod_Type'Succ( G_check_counter );
      if G_check_counter = 0 then
         read(PX4IO_PAGE_STATUS, PX4IO_P_STATUS_FLAGS, Status);
         if HIL.isSet( HIL.toUnsigned_16( Status ), PX4IO_P_STATUS_FLAGS_FAILSAFE ) then
            Logger.log_console(Logger.WARN, "PX4IO Failsafe");
         end if;
      end if;
      
   end sync_Outputs;
   


end PX4IO.Driver;
