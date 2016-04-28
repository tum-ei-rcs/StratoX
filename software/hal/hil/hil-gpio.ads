
package HIL.GPIO is
   --pragma Preelaborate;


   type GPIO_Signal_Type is(
      HIGH, LOW);

   type GPIO_Point_Type is (
      RED_LED
      -- HITCH,
      -- ELEVON_LEFT,   -- PWM shoud be access with write(ELEVON_LEFT, Angle)
      -- ELEVON_RIGHT   -- PWM
   );


   --function init return Boolean;

   procedure configure;

   procedure write (Point : in GPIO_Point_Type; Signal : in GPIO_Signal_Type);

   -- procedure read (Point : in GPIO_Point_Type; Signal : out GPIO_Signal_Type);

end HIL.GPIO;
