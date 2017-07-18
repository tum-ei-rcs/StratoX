--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--  Author:      Martin Becker (becker@rcs.ei.tum.de)
with HIL; use HIL;
with Ada.Unchecked_Conversion;
with Ada.Real_Time;    use Ada.Real_Time;
with ULog.Conversions; use ULog.Conversions;
with Interfaces;       use Interfaces;

--  @summary
--  Implements the structure andserialization of log objects
--  according to the self-describing ULOG file format used
--  in PX4.
--  The serialized byte array is returned.
package body ULog with SPARK_Mode => On is

   All_Defs : Boolean := False;
   Hdr_Def  : Boolean := False;
   Next_Def : Message_Type := Message_Type'First;

   ULOG_VERSION : constant HIL.Byte_Array := (1 => 16#1#);
   ULOG_MAGIC   : constant HIL.Byte_Array := (16#55#, 16#4c#, 16#6f#, 16#67#,
                                              16#01#, 16#12#, 16#35#);

   ULOG_MSG_HEAD  : constant HIL.Byte_Array := (16#A3#, 16#95#);
   ULOG_MTYPE_FMT : constant := 16#80#;

   --  each log message looks like this:
   --  +------------------+---------+----------------+
   --  | ULOG_MSG_HEAD(2) | Type(1) | Msg body (var) |
   --  +------------------+---------+----------------+
   --
   --  each body can be different. The header of the log file contains
   --  the definitions for the body by means of fixed-length
   --  FMT (0x80) messages, i.e., something like this:
   --  +------------------+------+--------------------+
   --  | ULOG_MSG_HEAD(2) | 0x80 | a definition (86B) |
   --  +------------------+------+--------------------+
   --  whereas 'definition' is as follows:
   --
   --  +---------+-----------+---------+------------+------------+
   --  | type[1] | length[1] | name[4] | format[16] | labels[64] |
   --  +---------+-----------+---------+------------+------------+
   --              ^^ full packet incl.header
   --
   --  Such FMT messages define the anatomy of 'msg body' for
   --  all messages with Type /= 0x80.

   ---------------------
   --  USER PROTOTYPES
   ---------------------

   --  add one Serialize_Ulog_* for each new message
   procedure Serialize_Ulog_GPS
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array)
     with Pre => msg.Typ = GPS;

   procedure Serialize_Ulog_IMU
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array)
     with Pre => msg.Typ = IMU;

   procedure Serialize_Ulog_Baro
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message; buf : out HIL.Byte_Array)
     with Pre => msg.Typ = BARO;

   procedure Serialize_Ulog_Mag
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array)
     with Pre => msg.Typ = MAG;

   procedure Serialize_Ulog_Controller
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array)
     with Pre => msg.Typ = CONTROLLER;

   procedure Serialize_Ulog_Nav
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array)
     with Pre => msg.Typ = NAV;

   procedure Serialize_Ulog_Text
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array)
     with Pre => msg.Typ = TEXT;

   procedure Serialize_Ulog_LogQ
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array)
     with Pre => msg.Typ = LOG_QUEUE;

   -------------------------
   --  INTERNAL PROTOTYPES
   -------------------------

   function Time_To_U64 (rtime : Ada.Real_Time.Time) return Unsigned_64
     with Pre => rtime >= Ada.Real_Time.Time_First;
     --  SPARK: "precond. might fail". Me: no (private type).

   procedure Serialize_Ulog_With_Tag
     (ct    : out ULog.Conversions.Conversion_Tag;
      msg   : in Message;
      len   : out Natural;
      bytes : out HIL.Byte_Array)
     with Post => len < 256 and --  ulog messages cannot be longer
     then len <= bytes'Length;

   ------------------------
   --  Serialize_Ulog_GPS
   ------------------------

   procedure Serialize_Ulog_GPS (ct : in out ULog.Conversions.Conversion_Tag;
                                 msg : in Message; buf : out HIL.Byte_Array) is
   begin
      Set_Name (ct, "GPS");
      Append_Float (ct, "lat", buf, msg.lat);
      Append_Float (ct, "lon", buf, msg.lon);
      Append_Float (ct, "alt", buf, msg.alt);
      Append_Uint8 (ct, "sat", buf, msg.nsat);
      Append_Uint8 (ct, "fix", buf, msg.fix);
      Append_Uint16 (ct, "yr", buf, msg.gps_year);
      Append_Uint8 (ct, "mon", buf, msg.gps_month);
      Append_Uint8 (ct, "day", buf, msg.gps_day);
      Append_Uint8 (ct, "h", buf, msg.gps_hour);
      Append_Uint8 (ct, "m", buf, msg.gps_min);
      Append_Uint8 (ct, "s", buf, msg.gps_sec);
      Append_Float (ct, "acc", buf, msg.pos_acc);
      Append_Float (ct, "v", buf, msg.vel);
   end Serialize_Ulog_GPS;
   --  pragma Annotate
   --   (GNATprove, Intentional, """buf"" is not initialized",
   --   "done by Martin Becker");

   ------------------------
   --  Serialize_Ulog_Nav
   ------------------------

   procedure Serialize_Ulog_Nav (ct : in out ULog.Conversions.Conversion_Tag;
                                 msg : in Message; buf : out HIL.Byte_Array) is
   begin
      Set_Name (ct, "NAV");
      Append_Float (ct, "dist", buf, msg.home_dist);
      Append_Float (ct, "crs", buf, msg.home_course);
      Append_Float (ct, "altd", buf, msg.home_altdiff);
   end Serialize_Ulog_Nav;

   ------------------------
   --  Serialize_Ulog_IMU
   ------------------------

   procedure Serialize_Ulog_IMU (ct : in out ULog.Conversions.Conversion_Tag;
                                 msg : in Message; buf : out HIL.Byte_Array) is
   begin
      Set_Name (ct, "IMU");
      Append_Float (ct, "accX", buf, msg.accX);
      Append_Float (ct, "accY", buf, msg.accY);
      Append_Float (ct, "accZ", buf, msg.accZ);
      Append_Float (ct, "gyroX", buf, msg.gyroX);
      Append_Float (ct, "gyroY", buf, msg.gyroY);
      Append_Float (ct, "gyroZ", buf, msg.gyroZ);
      Append_Float (ct, "roll", buf, msg.roll);
      Append_Float (ct, "pitch", buf, msg.pitch);
      Append_Float (ct, "yaw", buf, msg.yaw);
   end Serialize_Ulog_IMU;
   pragma Annotate
     (GNATprove, Intentional,
      """buf"" is not initialized", "done by Martin Becker");

   ------------------------
   --  Serialize_Ulog_BARO
   ------------------------

   procedure Serialize_Ulog_Baro
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array) is
   begin
      Set_Name (ct, "Baro");
      Append_Float (ct, "press", buf, msg.pressure);
      Append_Float (ct, "temp", buf, msg.temp);
      Append_Float (ct, "alt", buf, msg.press_alt);
   end Serialize_Ulog_Baro;
   pragma Annotate
     (GNATprove, Intentional,
      """buf"" is not initialized", "being done here");

   ------------------------
   --  Serialize_Ulog_MAG
   ------------------------

   procedure Serialize_Ulog_Mag
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array) is
   begin
      Set_Name (ct, "MAG");
      Append_Float (ct, "magX", buf, msg.magX);
      Append_Float (ct, "magY", buf, msg.magY);
      Append_Float (ct, "magZ", buf, msg.magZ);
   end Serialize_Ulog_Mag;
   pragma Annotate
     (GNATprove, Intentional,
      """buf"" is not initialized", "done by Martin Becker");


   -------------------------------
   --  Serialize_Ulog_Controller
   -------------------------------

   procedure Serialize_Ulog_Controller
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array) is
   begin
      Set_Name (ct, "Ctrl");
      Append_Uint8 (ct, "mode", buf, msg.ctrl_mode);
      Append_Float (ct, "TarYaw", buf, msg.target_yaw);
      Append_Float (ct, "TarRoll", buf, msg.target_roll);
      Append_Float (ct, "TarPitch", buf, msg.target_pitch);
      Append_Float (ct, "EleL", buf, msg.elevon_left);
      Append_Float (ct, "EleR", buf, msg.elevon_right);
   end Serialize_Ulog_Controller;
   pragma Annotate
     (GNATprove, Intentional,
      """buf"" is not initialized", "done by Martin Becker");

   ------------------------
   --  Serialize_Ulog_LogQ
   ------------------------

   procedure Serialize_Ulog_LogQ
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array) is
   begin
      Set_Name (ct, "LogQ");
      Append_Uint16 (ct, "ovf", buf, msg.n_overflows);
      Append_Uint8 (ct, "qd", buf, msg.n_queued);
      Append_Uint8 (ct, "max", buf, msg.max_queued);
   end Serialize_Ulog_LogQ;
   --  pragma Annotate
   --  (GNATprove, Intentional,
   --  """buf"" is not initialized", "done by Martin Becker");

   -------------------------
   --  Serialize_Ulog_Text
   -------------------------

   procedure Serialize_Ulog_Text
     (ct  : in out ULog.Conversions.Conversion_Tag;
      msg : in Message;
      buf : out HIL.Byte_Array) is
   begin
      Set_Name (ct, "Text");
      --  we allow 128B, but the longest field is 64B. split over two.
      declare
         txt : String renames msg.txt (msg.txt'First .. msg.txt'First + 63);
         len : Natural;
      begin
         if msg.txt_last > txt'Last then
            len := txt'Length;
         elsif msg.txt_last >= txt'First and then msg.txt_last <= txt'Last then
            len := (msg.txt_last - txt'First) + 1;
         else
            len := 0;
         end if;
         Append_String64 (ct, "text1", buf, txt, len);
      end;
      declare
         txt : String renames msg.txt (msg.txt'First + 64 .. msg.txt'Last);
         len : Natural;
      begin
         if msg.txt_last > txt'Last then
            len := txt'Length;
         elsif msg.txt_last >= txt'First and then msg.txt_last <= txt'Last then
            len := (msg.txt_last - txt'First) + 1;
         else
            len := 0;
         end if;
         Append_String64 (ct, "text2", buf, txt, len);
      end;
   end Serialize_Ulog_Text;
   pragma Annotate
     (GNATprove, Intentional,
      """buf"" is not initialized", "done by Martin Becker");

   --------------------
   --  Time_To_U64
   --------------------

   function Time_To_U64 (rtime : Ada.Real_Time.Time) return Unsigned_64 is
      tmp : Integer;
      u64 : Unsigned_64;
   begin
      tmp := (rtime - Ada.Real_Time.Time_First) /
        Ada.Real_Time.Microseconds (1);
      if tmp < Integer (Unsigned_64'First) then
         u64 := Unsigned_64'First;
      else
         u64 := Unsigned_64 (tmp);
      end if;
      return u64;
   end Time_To_U64;
   --  SPARK: "precondition might a fail".
   --  Me: "no (because Time_First is private and SPARK can't know)"

   --------------------
   --  Serialize_Ulog
   --------------------

   procedure Serialize_Ulog (msg : in Message; len : out Natural;
                             bytes : out HIL.Byte_Array) is
      ct : ULog.Conversions.Conversion_Tag;
   begin
      Serialize_Ulog_With_Tag
        (ct => ct, msg => msg, len => len, bytes => bytes);
      pragma Unreferenced (ct); -- caller doesn't want that
   end Serialize_Ulog;

   -----------------------------
   --  Serialize_Ulog_With_Tag
   -----------------------------

   procedure Serialize_Ulog_With_Tag (ct : out ULog.Conversions.Conversion_Tag;
                                      msg : in Message; len : out Natural;
                                      bytes : out HIL.Byte_Array) is
   begin
      New_Conversion (ct);
      --  write header
      Append_Unlabeled_Bytes
        (t => ct, buf => bytes, tail => ULOG_MSG_HEAD
         & HIL.Byte (Message_Type'Pos (msg.Typ)));
      pragma Annotate
        (GNATprove, Intentional,
         """bytes"" is not initialized", "done by Martin Becker");

      --  serialize the timestamp
      declare
         pragma Assume (msg.t >= Ada.Real_Time.Time_First); -- see a-reatim.ads
         time_usec : constant Unsigned_64 := Time_To_U64 (msg.t);
      begin
         Append_Uint64
           (t => ct, label => "t", buf => bytes, tail => time_usec);
      end;

      --  call the appropriate serializaton procedure for other components
      case msg.Typ is
         when NONE => null;
         when GPS =>
            Serialize_Ulog_GPS (ct, msg, bytes);
         when IMU =>
            Serialize_Ulog_IMU (ct, msg, bytes);
         when MAG =>
            Serialize_Ulog_Mag (ct, msg, bytes);
         when CONTROLLER =>
            Serialize_Ulog_Controller (ct, msg, bytes);
         when TEXT =>
            Serialize_Ulog_Text (ct, msg, bytes);
         when BARO =>
            Serialize_Ulog_Baro (ct, msg, bytes);
         when NAV =>
            Serialize_Ulog_Nav (ct, msg, bytes);
         when LOG_QUEUE =>
            Serialize_Ulog_LogQ (ct, msg, bytes);
      end case;

      --  read back the length, and drop incomplete messages
      declare
         SERLEN : constant Natural := Get_Size (ct);
      begin
         if Buffer_Overflow (ct) or SERLEN > bytes'Length or SERLEN > 255
         then
            len := 0;
         else
            len := SERLEN;
         end if;
      end;
      --  pragma Assert (len <= bytes'Length);
   end Serialize_Ulog_With_Tag;

   -------------------
   --  Serialize_CSV
   -------------------

   --   procedure Serialize_CSV
   --    (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array) is
   --     begin
   --        null;
   --     end Serialize_CSV;

   ---------------------
   --  Get_Header_Ulog
   ---------------------

   procedure Get_Header_Ulog
     (bytes : in out HIL.Byte_Array;
      len   : out Natural;
      valid : out Boolean) with SPARK_Mode => Off is
   begin
      if All_Defs then
         valid := False;

      elsif not Hdr_Def then
         --  before everything, return following ULog header:
         --  (not required by the spec, but it helps to recover the file
         --  when the SD logging goes wrong):
         --  +------------+---------+-----------+
         --  | File magic | version | timestamp |
         --  +------------+---------+-----------+
         declare
            timestamp : constant HIL.Byte_Array := (0, 0, 0, 0);
            l : constant Integer :=
              ULOG_MAGIC'Length + ULOG_VERSION'Length + timestamp'Length;
         begin
            if bytes'Length < l then
               len   := 0;
               valid := False;
            end if;
            bytes (bytes'First .. bytes'First + l - 1) :=
              ULOG_MAGIC & ULOG_VERSION & timestamp;
            len := l;
         end;
         Hdr_Def := True;
         valid   := True;

      else
         if Next_Def = NONE then
            len := 0;
         else
            --  now return FMT message with definition of current type.
            --  Skip type=NONE
            declare
               --  the following decl prevents spark mode.
               --  RM 4.4(2): subtype cons. cannot depend.
               --  simply comment for proof.
               m : Message (typ => Next_Def);

               FMT_HEAD : constant HIL.Byte_Array :=
                 ULOG_MSG_HEAD & ULOG_MTYPE_FMT;

               type FMT_Msg is record
                  HEAD : HIL.Byte_Array (1 .. 3);
                  typ  : HIL.Byte; -- auto: ID of message being described
                  len  : HIL.Byte; -- auto: length of packed message
                  name : ULog_Name; -- auto: short name of message
                  fmt  : ULog_Format; -- format string
                  lbl  : ULog_Label; -- label string
               end record
                 with Pack;

               FMT_MSGLEN : constant Natural := (FMT_Msg'Size + 7) / 8; -- ceil

               subtype foo is HIL.Byte_Array (1 .. FMT_MSGLEN);
               function To_Buffer is new
                 Ada.Unchecked_Conversion (FMT_Msg, foo);

               fmsg : FMT_Msg;
            begin
               if FMT_MSGLEN > bytes'Length then
                  len := 0; -- message too long for buffer...skip it
                  return;
               end if;

               fmsg.HEAD := FMT_HEAD;
               fmsg.typ  := HIL.Byte (Message_Type'Pos (Next_Def));
               --  actually serialize a dummy message and read back things
               declare
                  serbuf : HIL.Byte_Array (1 .. 512);
                  pragma Unreferenced (serbuf);
                  serlen : Natural;
               begin
                  declare
                     ct : ULog.Conversions.Conversion_Tag;
                  begin
                     Serialize_Ulog_With_Tag
                       (ct => ct, msg => m, len => serlen, bytes => serbuf);
                     fmsg.fmt  := ULog.Conversions.Get_Format (ct);
                     fmsg.name := ULog.Conversions.Get_Name (ct);
                     fmsg.lbl  := ULog.Conversions.Get_Labels (ct);
                  end;
                  fmsg.len := HIL.Byte (serlen);
               end;

               --  copy all over to caller
               bytes (bytes'First .. bytes'First + FMT_MSGLEN - 1) :=
                 To_Buffer (fmsg);
               len := FMT_MSGLEN;
            end;
         end if;

         if Next_Def < Message_Type'Last then
            Next_Def := Message_Type'Succ (Next_Def);
         else
            All_Defs := True;
         end if;
         valid := True;
      end if;

   end Get_Header_Ulog;

end ULog;
