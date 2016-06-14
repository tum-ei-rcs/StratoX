
with PX4IO.Driver;


package body Controller is

   -- init
   procedure initialize is
   begin
      PX4IO.Driver.initialize;
   end initialize;


   procedure activate is
   begin
      -- arm PX4IO
      PX4IO.Driver.arm;
   end activate;


   procedure deactivate is
   begin
      -- arm PX4IO
      PX4IO.Driver.disarm;
   end deactivate;


   procedure setTarget (location : GPS_Loacation_Type) is
   begin
      null;
   end setTarget;

   procedure runOneCycle(systemData : System_Data_Type) is
   begin
      PX4IO.Driver.sync_Outputs;
   end runOneCycle;

end Controller;
