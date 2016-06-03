-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: vector package
--
-- ToDo:
-- [ ] Implementation


with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Numerics.Generic_Real_Arrays;
with Units;

package Vector3D with SPARK_Mode is

   package Unit_Arrays is new Ada.Numerics.Generic_Real_Arrays(Unit_Type);

   subtype Scalar is Unit_Type;
   type Vector3D is new Unit_Arrays.Real_Vector(1 .. 3);

  type Cartesian_Dimension_Type is (X, Y, Z);
  type Polar_Dimesion_Type is (Phi, Rho, Psi);
  type Earth_Dimension_Type is (LONGITUDE, LATITUDE, ALTITUDE);

   type Karthesian_Vector_Type is Unit_Arrays.Real_Vector(Cartesian_Dimension_Type);

   type Length_Vector is Karthesian_Vector_Type of Length_Type;
   type Velocity_Vector is Karthesian_Vector_Type of Linear_Velocity_Type;
   type Acceleration_Vector is Karthesian_Vector_Type of Linear_Acceleration_Type;


   type Orientation_Dimension_Type is (R, P, Y);
   type Orientation_Vector is Unit_Arrays.Real_Vector(Orientation_Dimension_Type) of Angle_Type;


  type Vector3D_Type is tagged array (Cartesian_Dimension_Type);

   function "+"   (Right : Vector3D_Type)       return Vector3D_Type;
   function "-"   (Right : Vector3D_Type)       return Vector3D_Type;
   function "abs" (Right : Vector3D_Type)       return Vector3D_Type;

   function "+"   (Left, Right : Vector3D_Type) return Vector3D_Type;
   function "-"   (Left, Right : Vector3D_Type) return Vector3D_Type;

   function "*"   (Left, Right : Vector3D_Type) return Real'Base;

   function "abs" (Right : Vector3D_Type)       return Real'Base;



end Generic_Vector3D;
