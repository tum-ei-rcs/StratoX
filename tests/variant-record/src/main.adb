with Ada.Real_Time;
with Ada.Text_IO; use Ada.Text_IO;
with mylog;

procedure main with SPARK_Mode is
   m : mylog.logmsg;
   now : Ada.Real_Time.Time;
   buffer : mylog.msgarray (1 .. 10);
begin
   buffer (1) := m;
   now := Ada.Real_Time.Clock;
   m := (t => now, typ => mylog.GPS, lat => 11.1,  lon => 48.0);
   buffer (2) := m;

   for k in buffer'Range loop
      Put_Line ("Buffer(" & Integer'Image (k) & ")=" & mylog.msgtype'Image (buffer (k).typ));

   end loop;
end main;
