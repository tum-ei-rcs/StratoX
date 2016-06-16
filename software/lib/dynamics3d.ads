


with Units.Vectors; use Units.Vectors;
with Units; use Units;

package Dynamics3D is

   -- Rotation Systems
   type Tait_Bryan_Angle_Type is (ROLL, PITCH, YAW);
   type Euler_Angle_Type is (X1, Z2, X3);



   subtype Wind_Speed is
     Units.Linear_Velocity_Type range 0.0 .. 50.0; -- 180 km/h

--
--
--     type Pose_Type is record
--        position : GPS_Loacation_Type;
--        -- velocity :
--        orientation : Orientation_Vector;
--     end record;
--
--
--     type Shape_Type is (SPHERE, BOX);
--
--






   -- procedure transform( pose : Pose_Type; transformation : Transformation_Vector) is null;


   -- function Orientation (gravity_vector : Linear_Acceleration_Vector) return Orientation_Vector is null;



end Dynamics3D;
