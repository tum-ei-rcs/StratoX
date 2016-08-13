with Logger;
with Units;

package body Profiler with SPARK_Mode is


   procedure enableProfiling is
   begin
      G_state.isEnabled := True;
   end enableProfiling;

   procedure disableProfiling is
   begin
      G_state.isEnabled := False;
   end disableProfiling;

   procedure init(Self : in out Profile_Tag; name : String) is
      now : constant Time := Clock;
      maxlen : constant Integer := (if name'Length > Self.name'Length
                                    then Self.name'Length else name'Length);

      idx_s0 : constant Integer := Self.name'First;
      idx_s1 : constant Integer := idx_s0 - 1 + maxlen;

      idx_n0 : constant Integer := name'First;
      idx_n1 : constant Integer := idx_n0 - 1 + maxlen;
   begin
      Self.name(idx_s0 .. idx_s1) := name (idx_n0 .. idx_n1);
      Self.name_length := maxlen;
      Self.stop_Time := now;
      Self.start_Time := now;
   end init;

   procedure reset(Self : in out Profile_Tag) is
      now : constant Time := Clock;
   begin
      Self.max_duration := Milliseconds( 0 );
      Self.stop_Time := now;
      Self.start_Time := now;
   end reset;

   procedure start(Self : in out Profile_Tag) is
   begin
      Self.start_Time := Clock;
   end start;

   procedure stop(Self : in out Profile_Tag) is
   begin
      if CFG_PROFILER_PROFILING then
         Self.stop_Time := Clock;
         if Self.stop_Time - Self.start_Time > Self.max_duration then
            Self.max_duration := Self.stop_Time - Self.start_Time;
         end if;
      end if;
   end stop;

   procedure log(Self : in Profile_Tag) is
   begin
      if CFG_PROFILER_PROFILING and CFG_PROFILER_LOGGING then
         Logger.log_console (Logger.INFO, Self.name & " Profile: " & Integer'Image (
                             Integer( Float( Units.To_Time(Self.max_duration) ) * 1.0e6 ) ) & " us" );
      end if;
   end log;

   function get_Name(Self : in Profile_Tag) return String is
   begin
      return Self.name(1 .. Self.name_length);
   end get_Name;


   function get_Start(Self : in Profile_Tag) return Time is
   begin
      return Self.start_Time;
   end get_Start;

   function get_Stop(Self : in Profile_Tag) return Time is
   begin
      return Self.stop_Time;
   end get_Stop;

   -- elapsed time before stop or last measurement time after stop
   function get_Elapsed(Self : in Profile_Tag) return Time_Span with SPARK_Mode => Off is
      now : constant Time := Clock;
   begin
      return (if Self.stop_Time > Self.start_Time then
                 Self.stop_Time - Self.start_Time else
                    now - Self.start_Time
             );
   end get_Elapsed;

   function get_Max(Self : in Profile_Tag) return Time_Span is
   begin
      return Self.max_duration;
   end get_Max;


   procedure Read_From_Memory(Self : in out Profile_Tag) is
      pragma Unreferenced (Self);
   begin
      null;
   end Read_From_Memory;


   procedure Write_To_Memory(Self : in out Profile_Tag) is
      pragma Unreferenced (Self);
   begin
      null;
   end Write_To_Memory;


end Profiler;
