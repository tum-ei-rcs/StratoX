
with Interfaces; use Interfaces;
with PX4IO.Driver; use PX4IO;
with NVRAM;
with Types;
with Units;

package body Servo with SPARK_Mode is

   ------------
   --  Types
   ------------

   type Servo_Setting_Type is record
      left  : Servo_Angle_Type := Servo_Angle_Type (0.0);
      right : Servo_Angle_Type := Servo_Angle_Type (0.0);
   end record;

   -------------
   --  States
   -------------

   Last_Critical : Servo_Setting_Type;

   ----------------
   --  Initialize
   ----------------

   procedure initialize is
      nleft, nright : Integer_8;

      function Sat_Cast_ServoAngle is new Units.Saturated_Cast (Servo_Angle_Type);

   begin
      --  load most recent critical angles
      NVRAM.Load (NVRAM.VAR_SERVO_LEFT,  nleft);
      NVRAM.Load (NVRAM.VAR_SERVO_RIGHT, nright);

      --  init and move servos to given angle
      Last_Critical.left  := Sat_Cast_ServoAngle (Float (nleft));
      Last_Critical.right := Sat_Cast_ServoAngle (Float (nright));
      Driver.initialize (Last_Critical.left, Last_Critical.right);
   end initialize;

   ------------------------
   --  Set_Angle
   ------------------------

   procedure Set_Angle (servo : Servo_Type; angle : Servo_Angle_Type) is
   begin
      case(servo) is
         when LEFT_ELEVON =>
            Driver.set_Servo_Angle (Driver.LEFT_ELEVON, angle);

         when RIGHT_ELEVON =>
            Driver.set_Servo_Angle (Driver.RIGHT_ELEVON, angle);
      end case;
   end Set_Angle;

   ------------------------
   --  Set_Critical_Angle
   ------------------------

   procedure Set_Critical_Angle (servo : Servo_Type; angle : Servo_Angle_Type) is
   begin
      set_Angle (servo, angle);

      --  backup to NVRAM, if it has changed
      case servo is

         when LEFT_ELEVON =>
            if angle /= Last_Critical.left then
               declare
                  pos : constant Integer_8 := Types.Sat_Cast_Int8 (Float (angle));
               begin
                  NVRAM.Store (NVRAM.VAR_SERVO_LEFT, pos);
                  Last_Critical.left := angle;
               end;
            end if;

         when RIGHT_ELEVON =>
            if angle /= Last_Critical.right then
               declare
                  pos : constant Integer_8 := Types.Sat_Cast_Int8 (Float (angle));
               begin
                  NVRAM.Store (NVRAM.VAR_SERVO_RIGHT, pos);
                  Last_Critical.right := angle;
               end;
            end if;

      end case;
   end Set_Critical_Angle;

   --------------
   --  activate
   --------------

   procedure activate is
   begin
      -- arm PX4IO
      Driver.arm;
   end activate;

   ----------------
   --  deactivate
   ----------------

   procedure deactivate is
   begin
      -- arm PX4IO
      Driver.disarm;
   end deactivate;

   -----------
   --  sync
   -----------

   procedure sync is
   begin
      Driver.sync_Outputs;
   end sync;

end Servo;
