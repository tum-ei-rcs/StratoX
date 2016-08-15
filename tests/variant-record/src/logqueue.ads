with mylog; use mylog;

package LogQueue with SPARK_Mode is
   protected type queue is
      procedure Put (msg : mylog.logmsg) with
        Pre => msg.typ in mylog.msgtype'Range;
      -- SPARK does not know that

      entry Get (msg : out mylog.logmsg);
   private
      buf       : mylog.logmsg; -- unconstrained variant record => mutable. GNATprove doesn't see that
      Not_Empty : Boolean := False;
   end queue;

   myqueue : queue;

   procedure mytest;

end LogQueue;
