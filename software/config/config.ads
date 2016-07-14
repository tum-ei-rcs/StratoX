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

package Config is

   LED_PIN : constant := 12;

   BARO_I2C_ADDRESS : constant := 0;


   DEFAULT_LONGITUDE : constant := 11.60555;     -- Englischer Garten
   DEFAULT_LATITUDE  : constant := 48.16423;

   OPTIMAL_PITCH : constant := -5.0;

   -- Thresholds
   CFG_TARGET_ALTITUDE_THRESHOLD : constant := 40.0 * Meter;
   CFG_TARGET_ALTITUDE_THRESHOLD_TIME : constant := 10.0 * Second;

   CFG_DELTA_ALTITUDE_THRESH : constant := 100.0 * Meter;  -- Diff
   CFG_DELTA_ALTITUDE_THRESH_TIME : constant := 10.0 * Second;


   -- Limits
   CFG_SERVO_ANGLE_LIMIT_MIN : constant := -45.0 * Degree;
   CFG_SERVO_ANGLE_LIMIT_MAX : constant :=  45.0 * Degree;

   CFG_SERVO_PULSE_LENGTH_LIMIT_MIN : constant :=  1.100 * Milli*Second;
   CFG_SERVO_PULSE_LENGTH_LIMIT_MAX : constant :=  1.900 * Milli*Second;


   CFG_MOTOR_SPEED_LIMIT_MIN : constant := 0.0 * Degree / Second;
   CFG_MOTOR_SPEED_LIMIT_MAX : constant := 10.0 * 360.0 * Degree / Second;  -- Degree per Second

end Config;
