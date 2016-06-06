


with Units.Vectors; use Units.Vectors;
with Units; use Units;

package Dynamics3D is




--     type Linear_Dynamic_Vector is record
--        position : Position_Vector;
--        velocity : Linear_Velocity_Vector;
--        acceleration : Linear_Acceleration_Vector;
--     end record;
--
--     type Angular_Dynamic_Vector is record
--        orientation : Orientation_Vector;
--        velocity : Angular_Velocity_Vector;
--        acceleration : Angular_Acceleration_Vector;
--     end record;
--
--     type Transformation_Vector is record
--        translation : Translation_Vector;
--        rotation    : Rotation_Vector;
--     end record;
--
--
   type Longitude_Type is new Units.Angle_Type range -180.0 .. 180.0;
   type Latitude_Type is new Units.Angle_Type range -90.0 .. 90.0;
   type Altitute_Type is new Units.Length_Type range -10.0 .. 10_000.0;

   type GPS_Loacation_Type is record
      Longitude : Longitude_Type;
      Latitude  : Latitude_Type;
      Altitute  : Altitute_Type;
   end record;


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
