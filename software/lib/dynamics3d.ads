


with Units.Vectors; use Units.Vectors;
with Units; use Units;

package Dynamics3D is

   -- Rotation Systems
   type Tait_Bryan_Angle_Type is (ROLL, PITCH, YAW);
   type Euler_Angle_Type is (X1, Z2, X3);




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
--     type Body_Tag is tagged record
--        mass        : Mass_Type;
--        shape       : Shape_Type;
--        position    : Position_Vector;
--        orientation : Orientation_Vector;
--        linear_dynamic : Linear_Dynamic_Vector;
--        angular_dynamic : Angular_Dynamic_Vector;
--     end record;





   -- procedure transform( pose : Pose_Type; transformation : Transformation_Vector) is null;


   -- function Orientation (gravity_vector : Linear_Acceleration_Vector) return Orientation_Vector is null;



end Dynamics3D;
