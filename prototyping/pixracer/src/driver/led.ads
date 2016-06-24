--  Institution: Technische Universität München
--  Department: Realtime Computer Systems (RCS)
--  Project: StratoX
--  Module: LED Driver
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
--  Description: Control a single LED
--
--  ToDo: Support several LEDs

package LED with
     Spark_Mode is

   procedure init;
   procedure on;
   procedure off;

end LED;
