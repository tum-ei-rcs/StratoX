with ULog;
with ULog.GPS;
with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;

procedure main is
   msg     : ULog.Message; -- root type for polymorphism
   msg_gps : ULog.GPS.Message;

   procedure dispatcher (msg : ULog.Message'Class) is
      s : Interfaces.Unsigned_16 := ULog.Size(ULog.Message'Class(msg));
      recovered : ULog.GPS.Message := ULog.GPS.Message (msg);
   begin
      Put_Line ("Size=" & s'Img); -- not working (no dispatch)
      Put_Line ("Recovered=" & recovered.Describe_Func);
   end dispatcher;

   procedure consume (msg : ULog.Message'Class) is
      viewconversion : ULog.Message := ULog.Message (msg); -- that happens in the logger (polymorphism)
      v2 : ULog.Message'Class := msg; -- that actually works.
      namestring : String := msg.Describe_Func;
   begin
      Put_Line ("Original type=" & namestring); -- working
      Put_Line ("V1::");
      dispatcher (viewconversion);
      Put_Line ("V2::");
      dispatcher (v2);
   end consume;
begin

   consume (msg_gps); -- not working.
   consume (msg);

end main;
