-- General Profiler
-- Author: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: measures execution time between 'start' and 'stop'.
--              Stores maximum execution time.
--
-- Usage:       enter loop, call 'start', execute code, call 'stop'.
--              call 'get_Max' outside of loop to retrieve longest execution time.

-- ToDo: Add middle stops


with Ada.Real_Time; use Ada.Real_Time;

package Profiler with SPARK_Mode is


   type Profile_Tag is tagged private;

   CFG_PROFILER_PROFILING : constant Boolean := True;
   CFG_PROFILER_LOGGING   : constant Boolean := False;

   procedure enableProfiling;

   procedure disableProfiling;

   procedure init(Self : in out Profile_Tag; name : String);

   procedure reset(Self : in out Profile_Tag);

   procedure start(Self : in out Profile_Tag);

   procedure stop(Self : in out Profile_Tag);

   procedure log(Self : in Profile_Tag);

   function get_Name(Self : in Profile_Tag) return String;

   function get_Start(Self : in Profile_Tag) return Time;

   function get_Stop(Self : in Profile_Tag) return Time;

   -- elapsed time before stop or last measurement time after stop
   function get_Elapsed(Self : in Profile_Tag) return Time_Span;

   function get_Max(Self : in Profile_Tag) return Time_Span;

private
   subtype Name_Length_Type is Integer range 0 .. 30;
   subtype Name_Type is String(1 .. 30);

   type Profile_Tag is tagged record
      name         : Name_Type := (others => ' ');
      name_length  : Name_Length_Type := 0;
      max_duration : Time_Span := Milliseconds( 0 );
      start_Time   : Time := Time_First;
      stop_Time    : Time := Time_First;
   end record;

   type State_Type is record
      isEnabled : Boolean := True;
   end record;

   G_state : State_Type;

   procedure Read_From_Memory(Self : in out Profile_Tag);

   procedure Write_To_Memory(Self : in out Profile_Tag);

end Profiler;
