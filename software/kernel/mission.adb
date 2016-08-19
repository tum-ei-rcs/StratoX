
with Ada.Real_Time; use Ada.Real_Time;

with Units.Navigation; use Units.Navigation;
with Config.Software;
with HIL;

with Units; use Units;


with Console; use Console;
--  with Buzzer_Manager;
with LED_Manager;
with Logger;
--  with ULog;

with Estimator;
with Controller;
with NVRAM; use NVRAM;
with Interfaces; use Interfaces;


package body Mission with SPARK_Mode is

   type State_Type is record 
      mission_state  : Mission_State_Type := UNKNOWN;
      mission_event  : Mission_Event_Type := NONE;
      last_call_time : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
      gps_lock_threshold_time : Time_Type := 0.0 * Second;
      delta_threshold_time : Time_Type := 0.0 * Second;
      target_threshold_time : Time_Type := 0.0 * Second;
      home           : GPS_Loacation_Type := (Config.DEFAULT_LONGITUDE, 
                                             Config.DEFAULT_LATITUDE, 
                                             0.0 * Meter);
      body_info     : Body_Type;
      last_call     : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
      last_state_change : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
   end record;

   G_state : State_Type;
   
   
   
   procedure start_New_Mission is
   begin
      if G_state.mission_state = UNKNOWN or G_state.mission_state = WAITING_FOR_RESET then
         NVRAM.Reset;
         G_state.mission_state := INITIALIZING;
         Logger.log(Logger.INFO, "New Mission.");
      else
         Logger.log(Logger.WARN, "Mission running, cannot start new Mission!");
      end if;
   end start_New_Mission;
   
   procedure load_Mission is
      old_state_val : HIL.Byte;
      height : HIL.Byte_Array_2;
      baro_height : Altitude_Type;
   begin
      NVRAM.Load( VAR_MISSIONSTATE, old_state_val );
      G_state.mission_state := Mission_State_Type'Val( old_state_val );
      if G_state.mission_state = UNKNOWN or G_state.mission_state = WAITING_FOR_RESET then
         start_New_Mission;
      else
         -- Baro
         NVRAM.Load( VAR_HOME_HEIGHT_L, height(1) );
         pragma Annotate (GNATprove, False_Positive, """height"" might not be initialized", "it is done right here");
         NVRAM.Load( VAR_HOME_HEIGHT_H, height(2) );
         baro_height := Unit_Type( HIL.toUnsigned_16( height ) ) * Meter;
         
         -- GPS
         NVRAM.Load( VAR_GPS_TARGET_LONG_A, Float( G_state.home.Longitude ) );
         NVRAM.Load( VAR_GPS_TARGET_LAT_A,  Float( G_state.home.Latitude ) );
         NVRAM.Load( VAR_GPS_TARGET_ALT_A,  Float( G_state.home.Altitude ) );
         
         -- lock Home
         Logger.log(Logger.DEBUG, "Home Height: " & Image(G_state.home.Altitude) );  
         Estimator.lock_Home( G_state.home, baro_height );
         Controller.set_Target_Position( G_state.home );
         
         Logger.log(Logger.INFO, "Continue Mission at " & Integer'Image( Mission_State_Type'Pos( G_state.mission_state ) ) );
      end if;    
   end load_Mission;

      
   procedure handle_Event( event : Mission_Event_Type ) is
   begin
      null;
   end handle_Event;
   pragma Unreferenced (handle_Event);
   
   
   
   
   procedure next_State is
   begin
      G_state.mission_state := Mission_State_Type'Succ(G_state.mission_state);
      NVRAM.Store( VAR_MISSIONSTATE, Mission_State_Type'Pos( G_state.mission_state ) );
      G_state.last_state_change := Ada.Real_Time.Clock;
   end next_State;
   
   
   procedure perform_Initialization is
      -- The_Final_Countdown : Buzzer_Manager.Song_Type := ();
   begin
      G_state.last_state_change := Ada.Real_Time.Clock;
      G_state.body_info.orientation := (0.0 * Degree, 0.0 * Degree, 0.0 * Degree);
      G_state.body_info.position := (0.0 * Degree, 0.0 * Degree, 0.0 * Meter);
   
      -- set hold
      -- Controller.set_hold;
      
      Logger.log(Logger.INFO, "Mission Initialized");
      -- beep ever 10 seconds for one second at 1kHz.
      -- Buzzer_Manager.Set_Freq (1000.0 * Hertz);
      -- Buzzer_Manager.Set_Timing (period => 5.0 * Second, length => 1.0 * Second);
      -- Buzzer_Manager.Set_Song(The_Final_Countdown)
      -- Buzzer_Manager.Enable;  
      next_State;
   end perform_Initialization;

   procedure perform_Self_Test is
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      
      procedure lock_Home is
      begin
         G_state.home := Estimator.get_Position;
         Estimator.lock_Home(Estimator.get_Position, Estimator.get_Baro_Height);
         --G_state.home.Altitude := Estimator.get_current_Height;
         NVRAM.Store( VAR_HOME_HEIGHT_L, HIL.toBytes( Unsigned_16( Estimator.get_Baro_Height ) )(1) );
         NVRAM.Store( VAR_HOME_HEIGHT_H, HIL.toBytes( Unsigned_16( Estimator.get_Baro_Height ) )(2) );
         
         NVRAM.Store( VAR_GPS_TARGET_LONG_A, Float( G_state.home.Longitude ) );
         NVRAM.Store( VAR_GPS_TARGET_LAT_A,  Float( G_state.home.Latitude ) );
         NVRAM.Store( VAR_GPS_TARGET_ALT_A,  Float( G_state.home.Altitude ) );
         
         -- gib laut
         Controller.bark;
         
      end lock_Home;
      
   begin
   
      -- get initial values
      Estimator.update( (0.0*Degree, 0.0*Degree) );
      
      -- set hold
      Controller.set_hold;
      Controller.sync;

      -- check GPS lock
      if Estimator.get_GPS_Fix = FIX_3D then
         G_state.gps_lock_threshold_time := G_state.gps_lock_threshold_time + To_Time(now - G_state.last_call); 
         LED_Manager.LED_switchOn;
         
         if G_state.gps_lock_threshold_time > 10.0 * Second then
            lock_Home;
            Logger.log(Logger.INFO, "Mission Ready");
            next_State;
         end if;
      else
         G_state.gps_lock_threshold_time := 0.0 * Second;
      end if;

      -- FOR TEST
      if now > G_state.last_state_change + Config.Software.CFG_GPS_LOCK_TIMEOUT then
         lock_Home;
         next_State;
      end if;
      
   end perform_Self_Test;

   procedure wait_For_Arm is
   begin
      Estimator.update( (0.0*Degree, 0.0*Degree) );
      next_State;
   end wait_For_Arm;

   procedure wait_For_Release is
   begin
      Logger.log(Logger.INFO, "Start Ascending");
      next_State;
   end wait_For_Release;

   procedure monitor_Ascend is
      height : Altitude_Type := 0.0 * Meter;
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      -- Estimator
      Estimator.update( (0.0*Degree, 0.0*Degree) );
     
      -- set hold
      Controller.set_hold; 
      Controller.sync;
  
      -- check target height
      -- FIXME: Sprung von Baro auf GPS hat ausgelöst.
      --if Estimator.get_current_Height >= G_state.home.Altitude + Config.CFG_TARGET_ALTITUDE_THRESHOLD then
      if Estimator.get_relative_Height >= Config.CFG_TARGET_ALTITUDE_THRESHOLD then
         G_state.target_threshold_time := G_state.target_threshold_time + To_Time(now - G_state.last_call);  -- TODO: calc dT     
         if G_state.target_threshold_time >= Config.CFG_TARGET_ALTITUDE_THRESHOLD_TIME then
            Logger.log(Logger.INFO, "Target height reached. Detaching...");
            Logger.log(Logger.INFO, "Target height reached. Detaching...");
            next_State;
         end if;
      else
         G_state.target_threshold_time := 0.0 * Second;
      end if;
      
      -- check for accidential drop
      if Estimator.get_current_Height < Estimator.get_max_Height - Config.CFG_DELTA_ALTITUDE_THRESH then
         G_state.delta_threshold_time := G_state.delta_threshold_time + To_Time(now - G_state.last_call);  -- TODO: calc dT
         if G_state.delta_threshold_time >= Config.CFG_DELTA_ALTITUDE_THRESH_TIME then
            Logger.log(Logger.INFO, "Unplanned drop detected...");
            Logger.log(Logger.INFO, "Unplanned drop detected...");
            next_State;         
         end if;
      else
         G_state.delta_threshold_time := 0.0 * Second;  -- TODO: calc dT
      end if;
   
      -- Check Timeout
      if now > G_state.last_state_change + Units.To_Time_Span( Config.Software.CFG_ASCEND_TIMEOUT ) then   -- 600
         Logger.log(Logger.INFO, "Timeout Ascend");
         Logger.log(Logger.INFO, "Timeout Ascend");
         next_State;
      end if;
      
   end monitor_Ascend;
   
   procedure perform_Detach is
      isAttached : Boolean := True;
      start : Ada.Real_Time.Time := Ada.Real_Time.Clock; 
   begin
      Controller.activate;

      while isAttached loop
         Controller.set_detach;
         for k in Integer range 1 .. 40 loop
            start := Ada.Real_Time.Clock;
            Estimator.update( (0.0*Degree, 0.0*Degree) );
            Controller.sync;
            delay until start + Milliseconds(20);
         end loop;
         Controller.set_hold;
         for k in Integer range 1 .. 15 loop
            start := Ada.Real_Time.Clock;
            Estimator.update( (0.0*Degree, 0.0*Degree) );
            Controller.sync;
            delay until start + Milliseconds(20);
         end loop;
         Controller.set_detach;
         for k in Integer range 1 .. 30 loop
            start := Ada.Real_Time.Clock;
            Estimator.update( (0.0*Degree, 0.0*Degree) );
            Controller.sync;
            delay until start + Milliseconds(20);
         end loop;
         
         isAttached := False;
      end loop;
      
      Controller.set_Target_Position( G_state.home );
      Estimator.reset_log_calls;    
      Estimator.reset;
      
      Logger.log(Logger.INFO, "Detached");
      next_State;
   end perform_Detach;

   procedure control_Descend is
      now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      
      procedure deactivate is
      begin
         Controller.deactivate;
         next_State;  
         -- beep ever 10 seconds for one second at 1kHz.
         -- Buzzer_Manager.Set_Freq (1000.0 * Hertz);
         -- Buzzer_Manager.Set_Timing (period => 10.0 * Second, length => 1.0 * Second);
         -- Buzzer_Manager.Enable;  
      end deactivate;
      
      Elevons : Controller.Elevon_Angle_Array := Controller.get_Elevons;
   begin
      -- Estimator
      Estimator.update( (Elevons(Controller.RIGHT)/2.0 + Elevons(Controller.LEFT)/2.0,
                         Elevons(Controller.RIGHT)/2.0 - Elevons(Controller.LEFT)/2.0) );
      
      G_state.body_info.orientation := Estimator.get_Orientation;
      G_state.body_info.position := Estimator.get_Position;

      -- Controller
      Controller.set_Current_Orientation (G_state.body_info.orientation);
      Controller.set_Current_Position (G_state.body_info.position);
      Controller.runOneCycle; 
      
      
      
      -- Check stable position
      if Estimator.get_Stable_Time > 120.0 * Second then
         Logger.log(Logger.INFO, "Landed.");
         deactivate;
      end if;    
      
      -- Timeout for Landing
      if now > G_state.last_state_change + Config.Software.CFG_DESCEND_TIMEOUT then
         Logger.log(Logger.INFO, "Timeout. Landed");
         deactivate;
      end if;
      
      
   end control_Descend;

   procedure wait_On_Ground is
      command : Console.User_Command_Type;
   begin
   
      -- Buzzer_Manager.Tick;
      next_State;
   
      -- Console
      Console.read_Command( command );

      case ( command ) is
         when Console.DISARM =>
            Logger.log(Logger.INFO, "Mission Finished");
            next_State;
            
         when others =>
            null;
      end case;

   end wait_On_Ground;

   procedure wait_For_Reset is
   begin
      null;
   end wait_For_Reset;


   procedure run_Mission is
   begin
      case (G_state.mission_state) is
         when UNKNOWN => null;
         when INITIALIZING => 
            perform_Initialization;
            
         when SELF_TESTING =>
            perform_Self_Test;
            
         when WAITING_FOR_ARM =>
            wait_For_Arm;
            
         when WAITING_FOR_RELEASE =>
            wait_For_Release;
            
         when ASCENDING =>
            monitor_Ascend;               
            
         when DETACHING =>
            perform_Detach;
            
         when DESCENDING =>
            control_Descend;
         
         when WAITING_ON_GROUND =>
            wait_On_Ground;
            
         when WAITING_FOR_RESET =>
            wait_For_Reset;
            
      end case;
      
      G_state.last_call := Ada.Real_Time.Clock;
   end run_Mission;

end Mission;
