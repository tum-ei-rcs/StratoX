
package HIL.GPIO is
   --pragma Preelaborate;


   type GPIO_Signal_Type is(
      HIGH, LOW);

   type GPIO_Point_Type is (
      RED_LED,
      SPI_CS_BARO,
      SPI_CS_MPU6000,
      SPI_CS_LSM303D,
      SPI_CS_L3GD20H,
      SPI_CS_EXT

      -- HITCH,
      -- ELEVON_LEFT,   -- PWM shoud be access with write(ELEVON_LEFT, Angle)
      -- ELEVON_RIGHT   -- PWM
   );


   --function init return Boolean;

   procedure configure;

   -- precondition that Point is Output
   procedure write (Point : in GPIO_Point_Type; Signal : in GPIO_Signal_Type);

   -- procedure read (Point : in GPIO_Point_Type; Signal : out GPIO_Signal_Type);

end HIL.GPIO;
