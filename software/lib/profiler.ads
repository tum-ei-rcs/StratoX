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

package Profiler is



   type Profile_Tag is tagged private;

   procedure init(Self : in out Profile_Tag; name : String);

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
   subtype Name_Type is String(1 .. 30);

   type Profile_Tag is tagged record
      name         : Name_Type;
      name_length  : Natural := 0;
      max_duration : Time_Span := Milliseconds( 0 );
      start_Time   : Time := Clock;
      stop_Time    : Time := Clock;
   end record;


end Profiler;