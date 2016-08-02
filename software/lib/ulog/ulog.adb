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

   ----------------
   --  PROTOTYPES
   ----------------
   function Time_To_U64 (rtime : Ada.Real_Time.Time) return Unsigned_64
     with Pre => rtime >= Ada.Real_Time.Time_First;

   ------------------------
   --  Serialize_Ulog_GPS
   ------------------------

   procedure Serialize_Ulog_GPS (msg : in Message; buf : out HIL.Byte_Array) is
   begin
      Set_Name ("GPS");
      Append_Float ("lat", buf, msg.lat);
      Append_Float ("lon", buf, msg.lon);
      Append_Float ("alt", buf, msg.alt);
      Append_Uint8 ("sat", buf, msg.nsat);
      Append_Uint8 ("fix", buf, msg.fix);
      Append_Uint64 ("ms", buf, msg.gps_msec);
      Append_Int16 ("wk", buf, msg.gps_week);
   end Serialize_Ulog_GPS;

   procedure Serialize_Ulog_IMU (msg : in Message; buf : out HIL.Byte_Array) is
   begin
      Set_Name ("IMU");
      Append_Float ("accX", buf, msg.accX);
      Append_Float ("accY", buf, msg.accY);
      Append_Float ("accZ", buf, msg.accZ);
      Append_Float ("gyroX", buf, msg.gyroX);
      Append_Float ("gyroY", buf, msg.gyroY);
      Append_Float ("gyroZ", buf, msg.gyroZ);
      Append_Float ("roll", buf, msg.roll);
      Append_Float ("pitch", buf, msg.pitch);
      Append_Float ("yaw", buf, msg.yaw);
   end Serialize_Ulog_IMU;

   procedure Serialize_Ulog_Controller (msg : in Message; buf : out HIL.Byte_Array) is
   begin
      Set_Name ("Controller");
      Append_Float ("TarYaw", buf, msg.target_yaw);
      Append_Float ("TarRoll", buf, msg.target_roll);
      Append_Float ("EleL", buf, msg.elevon_left);
      Append_Float ("EleR", buf, msg.elevon_right);
   end Serialize_Ulog_Controller;



   procedure Serialize_Ulog_LogQ (msg : in Message; buf : out HIL.Byte_Array) is
   begin
      Set_Name ("LogQ");
      Append_Uint16 ("ovf", buf, msg.n_overflows);
      Append_Uint8 ("q", buf, msg.n_queued);
   end Serialize_Ulog_LogQ;

   -------------------------
   --  Serialize_Ulog_Text
   -------------------------

   procedure Serialize_Ulog_Text (msg : in Message; buf : out HIL.Byte_Array) is
   begin
      Set_Name ("Text");
      --  we allow 128B, but the longest field is 64B. split over two.
      declare
         txt : String renames msg.txt (msg.txt'First .. msg.txt'First + 63);
         len : Natural;
      begin
         if msg.txt_last > txt'Last then
            len := txt'Length;
         elsif msg.txt_last >= txt'First and then msg.txt_last <= txt'Last then
            len := msg.txt_last - txt'First + 1;
         else
            len := 0;
         end if;
         Append_String64 ("text1", buf, txt, len);
      end;
      declare
         txt : String renames msg.txt (msg.txt'First + 64 .. msg.txt'Last);
         len : Natural;
      begin
         if msg.txt_last > txt'Last then
            len := txt'Length;
         elsif msg.txt_last >= txt'First and then msg.txt_last <= txt'Last then
            len := msg.txt_last - txt'First + 1;
         else
            len := 0;
         end if;
         Append_String64 ("text2", buf, txt, len);
      end;
   end Serialize_Ulog_Text;

   --------------------
   --  Time_To_U64
   --------------------

   function Time_To_U64 (rtime : Ada.Real_Time.Time) return Unsigned_64 is
     (Unsigned_64 ((rtime - Ada.Real_Time.Time_First) / Ada.Real_Time.Microseconds (1)));
   --  SPARK: "precondition might a fail". Me: "no (because Time_First is private and SPARK can't know)"

   --------------------
   --  Serialize_Ulog
   --------------------

   procedure Serialize_Ulog (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array) is
   begin
      New_Conversion;
      --  write header
      Append_Unlabeled_Bytes (buf => bytes, tail => ULOG_MSG_HEAD
                              & HIL.Byte (Message_Type'Pos (msg.Typ)));

      --  serialize the timestamp
      declare
         time_usec : constant Unsigned_64 := Time_To_U64 (msg.t);
      begin
         Append_Uint64 (label => "t", buf => bytes, tail => time_usec);
      end;

      --  call the appropriate serializaton procedure for other components
      case msg.Typ is
         when NONE => null;
         when GPS =>
            Serialize_Ulog_GPS (msg, bytes);
         when IMU =>
            Serialize_Ulog_IMU (msg, bytes);
         when Controller =>
            Serialize_Ulog_Controller (msg, bytes);
         when TEXT =>
            Serialize_Ulog_Text (msg, bytes);
         when LOG_QUEUE =>
            Serialize_Ulog_LogQ (msg, bytes);
      end case;

      --  read back the length
      len := ULog.Conversions.Get_Size;
      if len > bytes'Length or len > 255 then
         len := 0; -- buffer overflow
      end if;
      --  pragma Assert (len <= bytes'Length);
   end Serialize_Ulog;

   -------------------
   --  Serialize_CSV
   -------------------

--     procedure Serialize_CSV (msg : in Message; len : out Natural; bytes : out HIL.Byte_Array) is
--     begin
--        null;
--     end Serialize_CSV;

   ---------------------
   --  Get_Header_Ulog
   ---------------------

   procedure Get_Header_Ulog (bytes : in out HIL.Byte_Array;
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
            l : constant Integer := ULOG_MAGIC'Length + ULOG_VERSION'Length + timestamp'Length;
         begin
            if bytes'Length < l then
               len := 0;
               valid := False;
            end if;
            bytes (bytes'First .. bytes'First + l - 1) := ULOG_MAGIC & ULOG_VERSION & timestamp;
            len := l;
         end;
         Hdr_Def := True;
         valid := True;

      else
         if Next_Def = NONE then
            len := 0;
         else
            --  now return FMT message with definition of current type. Skip type=NONE
            declare
               m : Message (typ => Next_Def); -- <== this prevents spark mode here.. RM 4.4(2): subtype cons. cannot depend. simply comment for proof.
               FMT_HEAD : constant HIL.Byte_Array := ULOG_MSG_HEAD & ULOG_MTYPE_FMT;

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
               function To_Buffer is new Ada.Unchecked_Conversion (FMT_Msg, foo);

               fmsg : FMT_Msg;
            begin
               if FMT_MSGLEN > bytes'Length then
                  len := 0; -- message too long for buffer...skip it
                  return;
               end if;

               fmsg.HEAD := FMT_HEAD;
               fmsg.typ := HIL.Byte (Message_Type'Pos (Next_Def));
               --  actually serialize a dummy message and read back the properties
               declare
                  serbuf : HIL.Byte_Array (1 .. 512);
                  pragma Unreferenced (serbuf);
                  serlen : Natural;
               begin
                  Serialize_Ulog (msg => m, len => serlen, bytes => serbuf);
                  fmsg.fmt := ULog.Conversions.Get_Format;
                  fmsg.name := ULog.Conversions.Get_Name;
                  fmsg.lbl := ULog.Conversions.Get_Labels;
                  fmsg.len := HIL.Byte (serlen);
               end;

               --  copy all over to caller
               bytes (bytes'First .. bytes'First + FMT_MSGLEN - 1) := To_Buffer (fmsg);
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

   ----------
   --  Init
   ----------

   procedure Init is
   begin
      All_Defs := False;
      Hdr_Def  := False;
      Next_Def := Message_Type'First;
      ULog.Conversions.Init_Conv;
   end Init;

end ULog;
