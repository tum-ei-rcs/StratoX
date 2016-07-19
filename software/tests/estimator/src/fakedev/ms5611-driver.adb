package body ms5611.driver  with
   SPARK_Mode,
   Refined_State => (State => null, Coefficients => null) is
   procedure reset is null;
   -- send a soft-reset to the device.

   procedure init is null;
   -- with Global => (IN_Out => (State, Coefficients));
   -- initialize the device, get chip-specific compensation values

   procedure update_val is null;
   -- trigger measurement update. Should be called periodically.

   function get_temperature return Temperature_Type is
      a : Temperature_Type;
   begin
      return a;
   end;
   -- get temperature from buffer
   -- @return the last known temperature measurement

   function get_pressure return Pressure_Type is
      a :  Pressure_Type;
   begin
      return a;
   end;
   -- get barometric pressure from buffer
   -- @return the last known pressure measurement

   procedure self_check (Status : out Error_Type) is null;
end ms5611.driver;
