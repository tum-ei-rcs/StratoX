with ULog;
with ULog.GPS;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Tags;
with Interfaces;

--  Rules for conversion in OO programming:
--  1. SPECIFIC TYPES: only up-cast (towards ancestors/base) possible
--    * view conversion, i.e., components not in parent are hidden
--    * tag stays untouched (really? then why no dispatching?)
--    * no initialization necessary
--    * not dispatching
--  2. CLASS-WIDE TYPES: both directions (ancestors <> descendant) possible
--    * view conversions
--    * requires initialization with specific
--    * dispatch works
--  3. VIEW RENAMING: to rename result of a view conversion
--    * view the result as target type
--    * optimal performance
--    * requires "initialization" with specific
--    * dispatch works
--  X. VIEW CONVERSION: if both source and target type are tagged, or
--    if appearing in a call as IN OUT or OUT paramete.
--  Y. VALUE CONVERSION: everything else
--  Z. DYAMIC DISPATCHING
--

procedure main is
   msg     : ULog.Message; -- root type for polymorphism
   msg_gps : ULog.GPS.Message;

   --  this procedure takes any member of the Ulog.Message class and makes dispatching calls
   procedure dispatcher (msg : ULog.Message'Class) is
      --  accepts any argument of tyme ULog.Message and its descendants
      s : Interfaces.Unsigned_16 := ULog.Size (msg); -- dynamic dispatching
   begin
      Put_Line ("Dispatched Tag =" & Ada.Tags.Expanded_Name (msg'Tag));
      Put_Line ("Dispatched type=" & msg.Describe_Func); -- this is not dispatching
      Put_Line ("Dispatched Size=" & s'Img);
   end dispatcher;

   --  this procedure applies the parent view (polymorphism)
   procedure consume (msg : ULog.Message'Class) is
      viewconversion : ULog.Message renames ULog.Message (msg);
      --  renaming declaration...not a new object. but a view conversion.
      --  why is this better then class-wide?

      classwide : ULog.Message'Class := msg;
      --  that can dispatch, but every such type needs initialization
      --  with specific type

      upcast : ULog.Message := ULog.Message (msg); -- not a view conv?
      --  looses dispatch functionality (is the tag the same?)
   begin
      Put_Line ("Original Tag =" & Ada.Tags.Expanded_Name (msg'Tag));
      Put_Line ("Original type=" & msg.Describe_Func);
      Put_Line ("-----------------");
      if ULog.Message'Class (upcast) in ULog.GPS.Message then
         Put_Line ("Upcast still is GPS");
      else
         Put_Line ("Upcast lost its tag");
      end if;
      declare
         tmp : ULog.Message'Class := upcast;
      begin
         Put_Line ("upcasted Tag =" & Ada.Tags.Expanded_Name (tmp'Tag));
      end;
      Put_Line ("-----------------");
      Put_Line ("viewconversion:");
      dispatcher (viewconversion); -- working
      Put_Line ("-----------------");
      Put_Line ("classwide:");
      dispatcher (classwide);
      Put_Line ("-----------------"); -- working
      Put_Line ("upcast:");
      dispatcher (ULog.Message'Class (upcast)); -- not dispatching

   end consume;

   m2 : Ulog.GPS.Message;

   m1 : Ulog.Message;

   n : String (1 .. 3);

begin

   consume (msg_gps);
   m2 := msg_gps.Copy;
   m2.Describe_Func(namestring => n); -- dispatching to gps
   Ada.Text_IO.Put_Line("I am a " & n);

end main;
