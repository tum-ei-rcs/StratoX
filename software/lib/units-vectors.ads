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

   package Unit_Arrays_Pack is new Ada.Numerics.Generic_Real_Arrays(Base_Unit_Type);

   subtype Scalar is Base_Unit_Type;
   type Vector3D_Type is array(1 .. 3) of Base_Unit_Type;


   type Polar_Coordinates_Type is (Phi, Rho, Psi);
   type Earth_Coordinates_Type is (LONGITUDE, LATITUDE, ALTITUDE);


   type Cartesian_Coordinates_Type is (X, Y, Z);
   type Cartesian_Vector_Type is array(Cartesian_Coordinates_Type) of Base_Unit_Type;


   subtype Translation_Vector_Array is Vector3D_Type; -- of Length_Type;

   --subtype Position_Vector is Karthesian_Vector_Type with Dimension => (Symbol => 'm', Meter => 1, others => 0);
--     type Dim_Vector_Type is array(Cartesian_Coordinates_Type) of Base_Unit_Type with Dimension_System =>
--          ((Unit_Name => Meter, Unit_Symbol => 'm', Dim_Symbol => 'L'),
--           (Unit_Name => Kilogram, Unit_Symbol => "kg", Dim_Symbol => 'M'),
--           (Unit_Name => Second, Unit_Symbol => 's', Dim_Symbol => 'T'),
--           (Unit_Name => Ampere, Unit_Symbol => 'A', Dim_Symbol => 'I'),
--           (Unit_Name => Kelvin, Unit_Symbol => 'K', Dim_Symbol => "Theta"),
--           (Unit_Name => Radian, Unit_Symbol => "Rad", Dim_Symbol => "A"));


   type Translation_Vector is array(Cartesian_Coordinates_Type) of Length_Type; -- of Length_Type;

   type Linear_Velocity_Vector is array(Cartesian_Coordinates_Type) of Linear_Velocity_Type;
   type Linear_Acceleration_Vector is array(Cartesian_Coordinates_Type) of Linear_Acceleration_Type;
--
--
--     type Orientation_Dimension_Type is (R, P, Y);
--     subtype Orientation_Vector_Type is Unit_Arrays.Real_Vector(Orientation_Dimension_Type) of Angle_Type;
--
--     subtype Orientation_Vector is Orientation_Vector_Type of Angle_Type;
--     subtype Rotation_Vector is Orientation_Vector_Type of Angle_Type;


   type Magnetic_Flux_Density_Vector is array(Cartesian_Coordinates_Type) of Magnetic_Flux_Density_Type;


   -- Rotation Systems
   type Tait_Bryan_Angle_Type is (ROLL, PITCH, YAW);
   type Euler_Angle_Type is (X1, Z2, X3);

   type Angular_Vector is array(Cartesian_Coordinates_Type) of Base_Unit_Type;

   type Unit_Vector is array(Tait_Bryan_Angle_Type) of Angle_Type;

   type Angle_Vector is array(Cartesian_Coordinates_Type) of Angle_Type;
   type Rotation_Vector is array(Cartesian_Coordinates_Type) of Angle_Type;

   type Angular_Velocity_Vector is array(Cartesian_Coordinates_Type) of Angular_Velocity_Type;
   type Angular_Acceleration_Vector is array(Cartesian_Coordinates_Type) of Angular_Velocity_Type;


   function "+" (Left, Right : Translation_Vector) return Translation_Vector is
      ( (  Left(X) + Right(X),
           Left(Y) + Right(Y),
           Left(Z) + Right(Z)
           ) );

   function "+" (Left, Right : Angle_Vector) return Angle_Vector is
      ( Left(X) + Right(X), Left(Y) + Right(Y), Left(Z) + Right(Z) );

   function "+" (Left, Right : Rotation_Vector) return Rotation_Vector is
      ( Left(X) + Right(X), Left(Y) + Right(Y), Left(Z) + Right(Z) );

   function "*" (Left : Base_Unit_Type; Right : Rotation_Vector) return Rotation_Vector is
      ( ( Unit_Type(Left) * Right(X), Unit_Type(Left) * Right(Y), Unit_Type(Left) * Right(Z) ) );


   function "+" (Left, Right : Angular_Velocity_Vector) return Angular_Velocity_Vector is
      ( (  Left(X) + Right(X),
           Left(Y) + Right(Y),
           Left(Z) + Right(Z)
           ) );

   function "-" (Left, Right : Angular_Velocity_Vector) return Angular_Velocity_Vector is
      ( (  Left(X) - Right(X),
           Left(Y) - Right(Y),
           Left(Z) - Right(Z)
           ) );

   function "*" (Left : Angular_Velocity_Vector; Right : Time_Type) return Rotation_Vector is
      ( ( Left(X) * Right, Left(Y) * Right, Left(Z) * Right ) );

   function "*" (Left : Linear_Velocity_Vector; Right : Time_Type) return Translation_Vector is
      ( ( Left(X) * Right, Left(Y) * Right, Left(Z) * Right ) );


   function Unit_Square (val : Base_Unit_Type) return Base_Unit_Type with
     Post => Unit_Square'Result >= Base_Unit_Type (0.0);
   --  numerically safe power val*val

   procedure rotate(vector : in out Cartesian_Vector_Type; axis : Cartesian_Coordinates_Type; angle : Angle_Type);

   function "abs" (vector : Cartesian_Vector_Type) return Base_Unit_Type;

   function "abs" (vector : Angular_Vector) return Base_Unit_Type;


   function "abs" (vector : Linear_Acceleration_Vector) return Linear_Acceleration_Type;



   -- Matrices
   subtype Unit_Matrix is Unit_Arrays_Pack.Real_Matrix; -- array(Natural <>, Natural <>) of



   type Unit_Vector2D is array(1..2) of Base_Unit_Type;
   type Unit_Matrix2D is array(1..2, 1..2) of Base_Unit_Type;

   -- subtype Unit_Vector2D is Unit_Arrays_Pack.Real_Vector(1..2);
   --subtype Unit_Vector3D is Unit_Arrays_Pack.Real_Vector(1..3);
   subtype Unit_Matrix3D is Unit_Arrays_Pack.Real_Matrix(1..3, 1..3);



   function "+" (Left, Right : Unit_Vector2D) return Unit_Vector2D is
     ( Left(1) + Right(1), Left(2) + Right(2) );

   function "-" (Left, Right : Unit_Vector2D) return Unit_Vector2D is
      ( Left(1) - Right(1), Left(2) - Right(2) );


   -- n×n Identity Matrix
   function Eye( n : Natural ) return Unit_Matrix;
   -- with Pre => n > 0;

   -- n×n Matrix with all elements 1.0
   function Ones( n : Natural ) return Unit_Matrix;
   -- with Pre => n > 0;

   -- n×n Matrix with all elements 0.0
   function Zeros( n : Natural ) return Unit_Matrix;
   -- with Pre => n > 0;


   procedure setOnes( A : in out Unit_Matrix; first : Natural; last : Natural);



end Units.Vectors;
