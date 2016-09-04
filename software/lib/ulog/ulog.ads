--  Institution: Technische Universitaet Muenchen
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with Ada.Real_Time;
with Interfaces;
with HIL;

--  @summary
--  Implements the structure andserialization of log objects
--  according to the self-describing ULOG file format used
--  in PX4.
--  The serialized byte array is returned.
--
--  Polymorphism with tagged type fails, because we cannot
--  copy a polymorphic object in SPARK.
--  TODO: offer a project-wide Ulog.Register_Parameter() function.
--
--  How to add a new message 'FOO':
--  1. add another enum value 'FOO' to Message_Type
--  2. extend record 'Message' with the case 'FOO'
--  3. add procedure  'Serialize_Ulog_FOO' and only handle the components for your new type
package ULog with SPARK_Mode is

   --  types of log messages. Add new ones when needed.
   type Message_Type is (NONE, TEXT, GPS, BARO, IMU, MAG, CONTROLLER, NAV, LOG_QUEUE);

   type GPS_fixtype is (NOFIX, DEADR, FIX2D, FIX3D, FIX3DDEADR, FIXTIME);

   --  polymorphism via variant record. Everything must be initialized
   type Message (Typ : Message_Type := NONE) is record
      t : Ada.Real_Time.Time := Ada.Real_Time.Time_First; --  time of data capture set by caller
      case Typ is
      when NONE => null;
      when TEXT =>
         --  text message with up to 128 characters
         txt : String (1 .. 128) := (others => Character'Val (0));
         txt_last : Integer := 0; -- points to last valid char
      when GPS =>
         --  GPS message
         gps_year  : Interfaces.Unsigned_16 := 0;
         gps_month : Interfaces.Unsigned_8 := 0;
         gps_day  : Interfaces.Unsigned_8  := 0;
         gps_hour : Interfaces.Unsigned_8  := 0;
         gps_min  : Interfaces.Unsigned_8  := 0;
         gps_sec  : Interfaces.Unsigned_8  := 0;
         fix      : Interfaces.Unsigned_8  := 0;
         nsat     : Interfaces.Unsigned_8  := 0;
         lat      : Float                  := 0.0;
         lon      : Float                  := 0.0;
         alt      : Float                  := 0.0;
         vel      : Float                  := 0.0;
      when BARO =>
         pressure : Float := 0.0;
         temp     : Float := 0.0;
      when IMU =>
         accX     : Float := 0.0;
         accY     : Float := 0.0;
         accZ     : Float := 0.0;
         gyroX    : Float := 0.0;
         gyroY    : Float := 0.0;
         gyroZ    : Float := 0.0;
         roll     : Float := 0.0;
         pitch    : Float := 0.0;
         yaw      : Float := 0.0;
      when MAG =>
         magX     : Float := 0.0;
         magY     : Float := 0.0;
         magZ     : Float := 0.0;
      when CONTROLLER =>
         ctrl_mode    : Interfaces.Unsigned_8 := 0;
         target_yaw   : Float := 0.0;
         target_roll  : Float := 0.0;
         target_pitch : Float := 0.0;
         elevon_left  : Float := 0.0;
         elevon_right : Float := 0.0;
      when NAV =>
         home_dist    : Float := 0.0;
         home_course  : Float := 0.0;
         home_altdiff : Float := 0.0;

      when LOG_QUEUE =>
         --  logging queue info
         n_overflows : Interfaces.Unsigned_16 := 0;
         n_queued    : Interfaces.Unsigned_8  := 0;
         max_queued  : Interfaces.Unsigned_8  := 0;
      end case;
   end record;

   --------------------------
   --  Primitive operations
   --------------------------

   procedure Serialize_Ulog (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array)
     with Post => len < 256 and --  ulog messages cannot be longer
     then len <= bytes'Length;
   --  turn object into ULOG byte array
   --  @return len=number of bytes written in 'bytes'

   --  procedure Serialize_CSV (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array);
   --  turn object into CSV string/byte array

   procedure Get_Header_Ulog (bytes : in out HIL.Byte_Array;
                              len : out Natural; valid : out Boolean)
     with Post => len <= bytes'Length;
   --  every ULOG file starts with a header, which is generated here
   --  for all known message types
   --  @return If true, you must keep calling this. If false, then all message defs have been
   --  delivered

   procedure Init;
   --  initialize this package before use

private

   subtype ULog_Label  is HIL.Byte_Array (1 .. 64);
   subtype ULog_Format is HIL.Byte_Array (1 .. 16);
   subtype ULog_Name   is HIL.Byte_Array (1 .. 4);
end ULog;
