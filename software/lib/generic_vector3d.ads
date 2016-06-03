-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Generic vector package
--
-- ToDo:
-- [ ] Implementation


with Ada.Numerics.Generic_Elementary_Functions;

generic
   type Index_Type is (3);
   type Data_Type is Float;
package Generic_Vector3D with SPARK_Mode is

  type Karthesian_Coordinate_Dimension_Type is (X, Y, Z);
  type Polar_Coordinate_Dimesion_Type is (Phi, Rho, Psi);
  type Earth_Coordinate_Dimension_Type is (LONGITUDE, LATITUDE, ALTITUDE);


  type Vector3D_Type is tagged array (Index_Type) of Float;

  type Karthesian_Vector_Type is record
     x : Data_Type;
     y : Data_Type;
     z : Data_Type;
  end record;

  function norm(vector : Karthesian_Vector_Type) return Data_Type;

   function "+"   (Right : Vector3D_Type) return Vector3D_Type;
   function "-"   (Right : Vector3D_Type) return Vector3D_Type;
   function "abs" (Right : Vector3D_Type) return Vector3D_Type;

end Generic_Vector3D;
