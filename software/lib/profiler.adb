with Logger;
with Units;

package body Profiler is

   procedure init(Self : in out Profile_Tag; name : String) is
      now : Time := Clock;
   begin
      Self.name(1 .. name'Length) := name;
      Self.name_length := name'Length;
      Self.stop_Time := now;
      Self.start_Time := now;
   end init;

   procedure start(Self : in out Profile_Tag) is
   begin
      Self.start_Time := Clock;
   end start;

   procedure stop(Self : in out Profile_Tag) is
   begin
      Self.stop_Time := Clock;
      if Self.stop_Time - Self.start_Time > Self.max_duration then
         Self.max_duration := Self.stop_Time - Self.start_Time;
      end if;
   end stop;

   procedure log(Self : in Profile_Tag) is
   begin
      Logger.log (Logger.INFO, Self.name & " Profile: " & Integer'Image ( Integer( Float( Units.To_Time(Self.max_duration) ) * 1000.0 ) ) & " ms" );
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
   function get_Elapsed(Self : in Profile_Tag) return Time_Span is
      now : Time := Clock;
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



end Profiler;
