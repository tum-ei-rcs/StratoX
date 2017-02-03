-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Units
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Additional units for navigation
--

with Interfaces;

package Units.Navigation with SPARK_Mode is

   subtype Heading_Type is Angle_Type range 0.0 * Degree .. DEGREE_360;

   function foo return Heading_Type;

end Units.Navigation;
