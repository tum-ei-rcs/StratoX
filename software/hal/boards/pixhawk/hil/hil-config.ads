--  @summary this package serves as config lookup in HIL.
--  actually this should not be here. Rather, HIL should
--  offer an API for that.
package HIL.Config is
      -- PX4IO
   PX4IO_BAUD_RATE_HZ : constant := 1_500_000;

    -- UBLOX Baudrate: Default: 9_600, PX4-FMU configured: 38_400
   UBLOX_BAUD_RATE_HZ : constant := 9_600;

   type Buzzer_Out_T is (BUZZER_USE_PORT, BUZZER_USE_AUX5);
   BUZZER_PORT : constant Buzzer_Out_T := BUZZER_USE_AUX5; -- Pixlite: BUZZER_USE_AUX5. Pixhawk: BUZZER_USE_PORT

   -- MPU6000
   MPU6000_SAMPLE_RATE_HZ : constant := 100;

end HIL.Config;
