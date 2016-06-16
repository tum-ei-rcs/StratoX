-- Ada Unit Library
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Library for physical calculations
--
-- ToDo:
-- [ ] rename to Units.Mechanics3D or Physics.Units, Physics.Vector3D




with Ada.Numerics.Generic_Real_Arrays;

package Units.Vectors with SPARK_Mode is

   package Unit_Arrays is new Ada.Numerics.Generic_Real_Arrays(Unit_Type);

   subtype Scalar is Unit_Type;
   type Vector3D_Type is array(1 .. 3) of Unit_Type;


   type Polar_Coordinates_Type is (Phi, Rho, Psi);
   type Earth_Coordinates_Type is (LONGITUDE, LATITUDE, ALTITUDE);


   type Cartesian_Coordinates_Type is (X, Y, Z);
   subtype Karthesian_Vector_Type is Unit_Arrays.Real_Vector(1 .. 3);


   subtype Translation_Vector_Array is Vector3D_Type; -- of Length_Type;

   --subtype Position_Vector is Karthesian_Vector_Type with Dimension => (Symbol => 'm', Meter => 1, others => 0);
   type Translation_Vector is array(1 .. 3) of Length_Type; -- of Length_Type;



   type Linear_Velocity_Vector is array(Cartesian_Coordinates_Type) of Linear_Velocity_Type;
   type Linear_Acceleration_Vector is array(Cartesian_Coordinates_Type) of Linear_Acceleration_Type;
--
--
--     type Orientation_Dimension_Type is (R, P, Y);
--     subtype Orientation_Vector_Type is Unit_Arrays.Real_Vector(Orientation_Dimension_Type) of Angle_Type;
--
--     subtype Orientation_Vector is Orientation_Vector_Type of Angle_Type;
--     subtype Rotation_Vector is Orientation_Vector_Type of Angle_Type;


   -- Rotation Systems
   type Tait_Bryan_Angle_Type is (ROLL, PITCH, YAW);
   type Euler_Angle_Type is (X1, Z2, X3);


   type Angular_Velocity_Vector is array(Tait_Bryan_Angle_Type) of Angular_Velocity_Type;
   type Angular_Acceleration_Vector is array(Tait_Bryan_Angle_Type) of Angular_Velocity_Type;


   function "+" (Left, Right : Translation_Vector) return Translation_Vector is
      ( (  Left(1) + Right(1),
           Left(2) + Right(2),
           Left(3) + Right(3)
           ) );


end Units.Vectors;
