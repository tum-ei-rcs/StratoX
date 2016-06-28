-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)

with HIL.Devices;

--  @summary
--  Target-independent specification for HIL of GPIO
package HIL.GPIO with SPARK_Mode is

   type GPIO_Signal_Type is(
      HIGH, LOW);

   type GPIO_Point_Type is new HIL.Devices.Device_Type_GPIO;

   subtype Point_Out_Type is GPIO_Point_Type;

   --subtype Ponit_In_Type is GPIO_Point_Type;


   --function init return Boolean;

   procedure configure;

   -- precondition that Point is Output
   procedure write (Point : in GPIO_Point_Type; Signal : in GPIO_Signal_Type);


   procedure read (Point : in GPIO_Point_Type; Signal : out GPIO_Signal_Type);

   procedure All_LEDs_Off;

   procedure All_LEDs_On;

end HIL.GPIO;
