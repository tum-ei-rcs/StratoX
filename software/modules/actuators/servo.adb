
with Interfaces; use Interfaces;
with PX4IO.Driver; use PX4IO;
with NVRAM;
with Types;
with Logger;

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
      Last_Critical.left  := Sat_Cast_ServoAngle (Float (Unit_Type (nleft) * Degree));
      Last_Critical.right := Sat_Cast_ServoAngle (Float (Unit_Type (nright) * Degree));
      Logger.log_console (Logger.DEBUG, "Servo restore: " &
                            AImage (Last_Critical.left) & " / "  &
                            AImage (Last_Critical.right));
      Driver.initialize (init_left => Last_Critical.left, init_right => Last_Critical.right);
   end initialize;

   ------------------------
   --  Set_Angle
   ------------------------

   procedure Set_Angle (which : Servo_Type; angle : Servo_Angle_Type) is
   begin
      case which is
         when LEFT_ELEVON =>
            Driver.Set_Servo_Angle (Driver.LEFT_ELEVON, angle);

         when RIGHT_ELEVON =>
            Driver.Set_Servo_Angle (Driver.RIGHT_ELEVON, angle);
      end case;
   end Set_Angle;

   ------------------------
   --  Set_Critical_Angle
   ------------------------

   procedure Set_Critical_Angle (which : Servo_Type; angle : Servo_Angle_Type) is
   begin
      Set_Angle (which, angle);

      --  backup to NVRAM, if it has changed
      case which is

         when LEFT_ELEVON =>
            if angle /= Last_Critical.left then
               declare
                  pos : constant Integer_8 := Types.Sat_Cast_Int8 (To_Degree (angle));
               begin
                  NVRAM.Store (NVRAM.VAR_SERVO_LEFT, pos);
                  Last_Critical.left := angle;
               end;
            end if;

         when RIGHT_ELEVON =>
            if angle /= Last_Critical.right then
               declare
                  pos : constant Integer_8 := Types.Sat_Cast_Int8 (To_Degree (angle));
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
