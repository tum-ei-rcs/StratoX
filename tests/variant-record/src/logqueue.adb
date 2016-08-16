package body LogQueue with SPARK_Mode is

   protected body queue is
      procedure Put (msg : mylog.logmsg) is
         buf_int : mylog.logmsg;
      begin
         buf := msg;
         buf_int := msg;
         Not_Empty := True;
      end Put;

      entry Get (msg : out mylog.logmsg) when Not_Empty is
         msg_ucon : mylog.logmsg (TEXT);
      begin
         msg := buf;
         msg_ucon := buf;
         Not_Empty := False;
      end Get;
   end queue;

   procedure mytest is
      msg_ucon : mylog.logmsg (GPS);
   begin
      myqueue.Get (msg_ucon); --  this call is not analyzed, because there is no
                              --  precondition. But we would need one to tell
                              --  that the parameter must be unconstrained
   end mytest;

end LogQueue;
