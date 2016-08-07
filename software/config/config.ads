-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Hardware Configuration
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description:
-- Hardware Configuration of the board.

with Units; use Units;
with Units.Navigation; use Units.Navigation;

package Config is

   -- Board
   -- -------------------------------
   LED_PIN : constant := 12;

   BARO_I2C_ADDRESS : constant := 0;





   -- Estimator
   -- -------------------------------
   DEFAULT_LONGITUDE : constant Longitude_Type := 11.60555 * Degree;     -- Englischer Garten
   DEFAULT_LATITUDE  : constant Latitude_Type := 48.16423 * Degree;

   TARGET_AREA_RADIUS : constant Length_Type := 50.0 * Meter;


   -- Flight
   -- -------------------------------
   OPTIMAL_PITCH : constant Pitch_Type := -3.0 * Degree;
   CIRCLE_TRAJECTORY_ROLL : constant Roll_Type := 5.0 * Degree;



   -- Mission
   -- -------------------------------
   CFG_TARGET_ALTITUDE_THRESHOLD : constant Altitude_Type := 100.0 * Meter;
   CFG_TARGET_ALTITUDE_THRESHOLD_TIME : constant := 6.0 * Second;

   CFG_DELTA_ALTITUDE_THRESH : constant Altitude_Type := 20.0 * Meter;  -- Diff
   CFG_DELTA_ALTITUDE_THRESH_TIME : constant := 2.0 * Second;


   -- Servos
   -- -------------------------------

   CFG_LEFT_SERVO_OFFSET  : constant := 8.0 * Degree;
   CFG_RIGHT_SERVO_OFFSET : constant := 4.0 * Degree;

   -- Limits
   CFG_SERVO_ANGLE_LIMIT_MIN : constant := -45.0 * Degree;
   CFG_SERVO_ANGLE_LIMIT_MAX : constant :=  45.0 * Degree;

   CFG_SERVO_PULSE_LENGTH_LIMIT_MIN : constant :=  1.100 * Milli*Second;
   CFG_SERVO_PULSE_LENGTH_LIMIT_MAX : constant :=  1.900 * Milli*Second;


   CFG_MOTOR_SPEED_LIMIT_MIN : constant := 0.0 * Degree / Second;
   CFG_MOTOR_SPEED_LIMIT_MAX : constant := 10.0 * 360.0 * Degree / Second;  -- Degree per Second



   -- Parameter Server
   -- organize parameters in groups

   type Float_Parameter_Type is( TIMEOUT_TEST,
                                 BUADRATE
                                 );

   type FLoat_Parameter_Array is array( Float_Parameter_Type ) of Float;



   -- procedure get_Parameter( param : Float_Parameter_Type; value : out Float );




end Config;
