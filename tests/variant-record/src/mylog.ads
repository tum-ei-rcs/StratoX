with Ada.Real_Time; use Ada.Real_Time;

package mylog with SPARK_Mode is

   type msgtype is (NONE, TEXT, GPS);

   type logmsg (typ : msgtype := NONE) is record
      t : Time := Time_First;
      case typ is
      when NONE => null;
      when TEXT =>
         txt : String (1 .. 128) := (others => Character'Val (0));
         txt_last : Integer := 0;
      when GPS =>
         lat : Float := 0.0;
         lon : Float := 0.0;
      end case;
   end record;

   type msgarray is array (Positive range <>) of logmsg;

   --  primitive ops
   procedure Print (m : logmsg);
end mylog;
