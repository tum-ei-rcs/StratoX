package p1 with SPARK_Mode,
  Abstract_State => (Only_Writing_Parameters, Internals)
is
   procedure write_on_bus(Device : Integer; Data : Integer) with
     Global => (Input => Only_Writing_Parameters );
   -- write some data to some device
end p1;
