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

   --  this procedure makes dispatching calls
   procedure dispatcher (msg : ULog.Message'Class) is
      --  accepts any argument of tyme ULog.Message and its descendants
      s : Interfaces.Unsigned_16 := ULog.Size (msg); -- dynamic dispatching happens here
   begin
      Put_Line ("Dispatched Tag =" & Ada.Tags.Expanded_Name (msg'Tag));
      Put_Line ("Dispatched type=" & msg.Describe_Func);
      Put_Line ("Dispatched Size=" & s'Img);
   end dispatcher;

   --  this procedure applies the parent view (polymorphism)
   procedure consume (msg : ULog.Message'Class) is
      viewconversion : ULog.Message renames ULog.Message (msg);
      --  renaming declaration...not a new object. but a view conversion.
      --  why is this better then class-wide?

      classwide : ULog.Message'Class := msg;
      --  that can dispatch, but every such type needs initialization with specific type

      upcast : ULog.Message := ULog.Message (msg);
      --  looses dispatch functionality (is the tag the same?)
   begin
      Put_Line ("Original type=" & msg.Describe_Func);
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

begin

   consume (msg_gps);
   --  consume (msg);
   msg_gps.Describe;

end main;
