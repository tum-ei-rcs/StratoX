
-- generic
--	type GPIO_Point;
package HAL.GPIO_Interface is
   pragma Preelaborate;

   type GPIO_Point is limited interface;

   -- type GPIO_Configuration is abstract;

   type GPIO_Signal_Type is (HIGH, LOW);
   --type GPIO_Signal_Type is limited interface;

   -- interface to configure a point. Configuration can hold direction, speed, etc
   --procedure configure(Point : in out GPIO_Point, Configuration : GPIO_Configuration);


   procedure write (Point : GPIO_Point; Signal : GPIO_Signal_Type) is abstract;

   function read (Point : GPIO_Point) return GPIO_Signal_Type is abstract;

end HAL.GPIO_Interface;
