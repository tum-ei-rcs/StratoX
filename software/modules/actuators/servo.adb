
with PX4IO.Driver; use PX4IO;

package body Servo is

   -- init
   procedure initialize is
   begin
      Driver.initialize;
   end initialize;

   procedure set_Angle(servo : Servo_Type; angle : Angle_Type) is
   begin
      case(servo) is
         when LEFT_ELEVON =>
            Driver.set_Servo_Angle(Driver.LEFT_ELEVON, angle);

         when RIGHT_ELEVON =>
            Driver.set_Servo_Angle(Driver.RIGHT_ELEVON, angle);
      end case;
   end set_Angle;

   procedure activate is
   begin
      -- arm PX4IO
      Driver.arm;
   end activate;

   procedure deactivate is
   begin
      -- arm PX4IO
      Driver.disarm;
   end deactivate;

   procedure sync is
   begin
      Driver.sync_Outputs;
   end sync;

end Servo;
