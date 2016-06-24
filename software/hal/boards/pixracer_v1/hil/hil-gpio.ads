-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Hardware Interface Layer for the GPIO


package HIL.GPIO with SPARK_Mode is

   type GPIO_Signal_Type is(
      HIGH, LOW);

   type GPIO_Point_Type is (
                            RED_LED,
                            GRN_LED,
                            BLU_LED,
                            SPI_CS_BARO,
                            SPI_CS_FRAM
   );

   subtype Point_Out_Type is GPIO_Point_Type;

   --subtype Ponit_In_Type is GPIO_Point_Type;


   --function init return Boolean;

   procedure configure;

   -- precondition that Point is Output
   procedure write (Point : in GPIO_Point_Type; Signal : in GPIO_Signal_Type);


   procedure read (Point : in GPIO_Point_Type; Signal : out GPIO_Signal_Type);

end HIL.GPIO;
