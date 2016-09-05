--  Institution: Technische Universitaet Muenchen
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--  Module:      PX4IO Driver
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--           Martin Becker (becker@rcs.ei.tum.de)
--
--  @summary Driver for the PX4IO co-processor
with HIL; use HIL;
with HIL.UART;
with Units; use Units;
with Config; use Config;
with Interfaces; use Interfaces;

package PX4IO.Driver with SPARK_Mode,
  Abstract_State => (Servo_Wish, Servo_State, Servo_Settings)
is
   
   MOTOR_SPEED_LIMIT_MIN : constant := CFG_MOTOR_SPEED_LIMIT_MIN;
   MOTOR_SPEED_LIMIT_MAX : constant := CFG_MOTOR_SPEED_LIMIT_MAX;

   SERVO_PULSE_LENGTH_LIMIT_MIN : constant := Unsigned_16 ( CFG_SERVO_PULSE_LENGTH_LIMIT_MIN / (1.0 * Micro * Second) ); -- Integer of Microseconds
   SERVO_PULSE_LENGTH_LIMIT_MAX : constant := Unsigned_16 ( CFG_SERVO_PULSE_LENGTH_LIMIT_MAX / (1.0 * Micro * Second) );

   --G_Pulse : Unsigned_16 := SERVO_PULSE_LENGTH_LIMIT_MIN;

   type Servo_Type is (LEFT_ELEVON, RIGHT_ELEVON); 
   
   subtype Servo_Angle_Type is Units.Angle_Type range 
      CFG_SERVO_ANGLE_LIMIT_MIN .. CFG_SERVO_ANGLE_LIMIT_MAX;
   
   subtype Motor_Speed_Type is Units.Angular_Velocity_Type range
      MOTOR_SPEED_LIMIT_MIN .. MOTOR_SPEED_LIMIT_MAX;
   

   procedure initialize (init_left : Servo_Angle_Type;
                         init_right : Servo_Angle_Type);
   
   procedure Self_Check (result : out Boolean);
   
   procedure arm;
   
   procedure disarm;
   
   procedure read_Status;

   procedure Set_Servo_Angle (servo : Servo_Type; angle : Servo_Angle_Type) with
     Global => (Input => Servo_Settings,
                In_Out => Servo_Wish); -- FIXME: why does SPARK force IN mode here?
       
   procedure sync_Outputs ;
--     with
--       Global => (Input => (Servo_Wish),
--                  Output => Servo_State);


private
   subtype Page_Type is HIL.Byte;
   subtype Offset_Type is HIL.Byte;
   
   subtype Data_Type is HIL.UART.Data_Type;
   
   function valid_Package( data : in Data_Type ) return Boolean with
     Pre => 2 in data'Range;
   
   procedure write(page : Page_Type; offset : Offset_Type; data : Data_Type; retries : Natural := 2) 
   with Pre => data'Length mod 2 = 0 and data'Length <= 64;

end PX4IO.Driver;
