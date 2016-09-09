-- Description:
-- Main System File
-- the main loop (TM)

with Ada.Real_Time;    use Ada.Real_Time;

with CPU;
with Units;            use Units;
--  with Units.Navigation; use Units.Navigation;

with HIL;
with Interfaces;      use Interfaces;

with MPU6000.Driver;  use MPU6000.Driver;
with PX4IO.Driver;
with ublox8.Driver;   use ublox8.Driver;
with NVRAM;
with Logger;
with Config.Software; use Config.Software;
with Bounded_Image;   use Bounded_Image;

with Mission;         use Mission;
--  with Console;
with Estimator;
with Controller;
with LED_Manager;
with Buzzer_Manager;
with Buildinfo;
with Profiler; use Profiler;

package body Main with SPARK_Mode => On is

   type LED_Counter_Type is mod 1000/Config.Software.MAIN_TICK_RATE_MS/2;
   G_led_counter : LED_Counter_Type := 0;

   ----------------
   --  Initialize
   ----------------

   procedure Initialize is
      num_boots : HIL.Byte;
   begin
      CPU.initialize;

      --  start logger first
      declare
         ret : Logger.Init_Error_Code;
      begin
         Logger.Init (ret);
         pragma Unreferenced (ret);
      end;
      Logger.Set_Log_Level (CFG_LOGGER_LEVEL_UART);

      -- wait to satisfy some (?) timing
      declare
         now : constant Time := Clock;
      begin
         delay until now + Milliseconds (50);
      end;

      if Config.Software.TEST_MODE_ACTIVE then
         Logger.log_console (Logger.ERROR, "TEST-DUMMY MODE IS ACTIVE!");
      end if;

      --  start NVRAM (bootcounter...)
      Logger.log_console (Logger.INFO, "Initializing NVRAM...");
      NVRAM.Init;

      --  from now on, log everything to SDcard
      Logger.log_console (Logger.INFO, "Starting SDLog...");
      Logger.Start_SDLog; -- should be called after NVRAM.Init

      Buzzer_Manager.Initialize;
      Estimator.initialize;
      Controller.initialize;

      --  wait a bit: UART doesn't seem to write earlier.
      declare
         now : constant Time := Clock;
      begin
         delay until now + Milliseconds (1000); -- reduced from 1500
      end;

      --  Dump general boot & crash info
      declare
         exception_line    : HIL.Byte_Array_2 := (0,0);
         exception_addr    : Unsigned_32;
         high_watermark_us : Unsigned_32;
      begin
         NVRAM.Load (NVRAM.VAR_BOOTCOUNTER, num_boots); -- is maintained by the NVRAM itself
         declare
            strboot : constant String := Unsigned8_Img (num_boots);
         begin
            Logger.log_console (Logger.INFO, ("Boot number: " & strboot));
            Logger.log_console (Logger.INFO, "Build date: " & Buildinfo.Compilation_ISO_Date
                                & " " & Buildinfo.Compilation_Time);
         end;
         NVRAM.Load (NVRAM.VAR_EXCEPTION_LINE_L, exception_line(1));
         NVRAM.Load (NVRAM.VAR_EXCEPTION_LINE_H, exception_line(2));
         NVRAM.Load (NVRAM.VAR_EXCEPTION_ADDR_A, exception_addr);
         --  write to SD card and console: last crash info
         Logger.log (Logger.WARN, "Last Exception: line=" &
                       Integer_Img (Integer (HIL.toUnsigned_16 (exception_line))) &
                       " addr=" & Unsigned_Img (exception_addr));
         NVRAM.Load (NVRAM.VAR_HIGHWATERMARK_A, high_watermark_us);
         Logger.log (Logger.WARN, "High Watermark: " & Unsigned_Img (high_watermark_us));
      end;

      Mission.load_Mission;

   end Initialize;

   -----------------------
   --  Perform_Self_Test
   -----------------------

   procedure Perform_Self_Test (passed : out Boolean) is
      in_air_reset : constant Boolean := Mission.Is_Resumed;
   begin

      if in_air_reset then
         passed := True;
         Logger.log_console (Logger.INFO, "In-Air reset, no self-check");
         return;
      end if;

      Logger.log_console (Logger.INFO, "Starting Self Test");

      --  check NVRAM
      NVRAM.Self_Check (passed);
      if not passed then
         Logger.log_console (Logger.ERROR, "NVRAM self-check failed");
         return;
      else
         Logger.log_console (Logger.INFO, "NVRAM self-check passed");
      end if;

      --  check MPU6000
      declare
         Status : Boolean;
      begin
         MPU6000.Driver.Self_Test (Status);
         passed := Status;
      end;
      if not passed then
         Logger.log_console (Logger.ERROR, "MPU6000 self-check failed");
         return;
      else
         Logger.log_console (Logger.INFO, "MPU6000 self-check passed");
      end if;

      --  check PX4IO
      declare
         Status : Boolean;
      begin
         PX4IO.Driver.Self_Check (Status);
         passed := Status;
      end;
      if not passed then
         Logger.log_console (Logger.ERROR, "PX4IO self-check failed; continuing anyway");
         --return; -- this happens a lot
      else
         Logger.log_console (Logger.INFO, "PX4IO self-check passed");
      end if;

      --  check GPS
      declare
         Status : ublox8.Driver.Error_Type;
      begin
         ublox8.Driver.perform_Self_Check (Status);
         passed := Status = ublox8.Driver.SUCCESS;
      end;
      if not passed then
         Logger.log_console (Logger.ERROR, "Ublox8 self-check failed");
         return;
      else
         Logger.log_console (Logger.INFO, "Ublox8 self-check passed");
      end if;

   end Perform_Self_Test;

   --------------
   --  Run_Loop
   --------------

   procedure Run_Loop is
      msg     : constant String := "Main";

      time_next_loop  : Time;
      time_loop_start : Time;
      Main_Profile : Profile_Tag;

      --command : Console.User_Command_Type;

      type skipper is mod 100; -- every 2 seconds one perf log
      skip : skipper := 0;
      watermark_high_us : Unsigned_32 := 0;
      watermark_last_us : Unsigned_32 := 0;

      m_state : Mission.Mission_State_Type;

   begin
      Main_Profile.init(name => "Main");
      LED_Manager.LED_blink (LED_Manager.SLOW);

      NVRAM.Load (NVRAM.VAR_HIGHWATERMARK_A, watermark_high_us);

      Logger.log_console (Logger.INFO, msg);

      --  arm PX4IO
      Controller.activate;

      time_next_loop := Clock;
      loop
         Main_Profile.start;
         time_loop_start := Clock;
         skip := skip + 1;

         -- LED alive: toggle with main loop, which allows to see irregularities
         G_led_counter := LED_Counter_Type'Succ( G_led_counter );
         if G_led_counter < LED_Counter_Type'Last/2 then
            LED_Manager.LED_switchOn;
         else
            LED_Manager.LED_switchOff;
         end if;

         --  do not use the buzzer here...just call tick. The only one who may buzzer is mission.adb
         Buzzer_Manager.Tick;

         --  Mission
         m_state := Mission.get_state;
         Mission.run_Mission; -- may switch to next one

--           -- Console
--           Console.read_Command( command );
--
--           case ( command ) is
--              when Console.TEST =>
--                 perform_Self_Test (checks_passed);
--                 if not checks_passed then
--                    Logger.log_console (Logger.ERROR, "Self-checks failed");
--                 else
--                    Logger.log_console (Logger.INFO, "Self-checks passed");
--                 end if;
--
--              when Console.STATUS =>
--                 Estimator.log_Info;
--                 Controller.log_Info;
--                 PX4IO.Driver.read_Status;
--
--                 Logger.log_console (Logger.INFO, "Profile: " & Integer_Img ( Integer(
--                                     Float( Units.To_Time(loop_duration_max) ) * 1000.0 ) ) & " ms" );
--
--              when Console.ARM => Controller.activate;
--
--              when Console.DISARM => Controller.deactivate;
--
--              when Console.PROFILE =>
--                 Logger.log_console (Logger.INFO, "Profile: " & Integer_Img ( Integer(
--                                     Float( Units.To_Time(loop_duration_max) ) * 1000.0 ) ) & " ms" );
--                 Main_Profile.log;
--
--              when others =>
--                 null;
--           end case;

         --  Maintain high watermark

         Main_Profile.stop;
         if m_state /= Mission.DETACHING and then m_state /= Mission.STARTING then
            --  we measure the loop time, except in detach and start. Because there we screw with timing
            declare
               t_watermark_sec  : constant Float := Float (To_Time (Main_Profile.get_Max));
               t_watermark_usec : constant Float := t_watermark_sec * 1.0E6;
            begin
               if t_watermark_usec > 0.0 then
                  if Float (Unsigned_32'Last) > t_watermark_usec then
                     watermark_last_us := Unsigned_32 (t_watermark_usec);
                  else
                     watermark_last_us := Unsigned_32'Last;
                  end if;
                  if watermark_last_us > watermark_high_us then
                     watermark_high_us := watermark_last_us;
                     NVRAM.Store (NVRAM.VAR_HIGHWATERMARK_A, watermark_high_us);
                  end if;
                  if skip = 0 then
                     Main_Profile.reset;
                     Logger.log_console (Logger.DEBUG, "Main Time: cur=" & Unsigned_Img (watermark_last_us)
                                         & ", high=" & Unsigned_Img (watermark_high_us));
                  end if;
               end if;
            end;
         else
            --  recover timing
            Main_Profile.reset;
            time_next_loop := time_loop_start;
         end if;

         --  wait remaining loop time
         time_next_loop := time_next_loop + Milliseconds (MAIN_TICK_RATE_MS);
         delay until time_next_loop;
      end loop;

   end Run_Loop;


end Main;
