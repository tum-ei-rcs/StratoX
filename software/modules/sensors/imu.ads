

with Generic_Sensor;
with Interfaces; use Interfaces;

with Units; use Units;
with Units.Vectors; use Units.Vectors;
with Units.Navigation; use Units.Navigation;
with MPU6000.Driver; use MPU6000;


package IMU with SPARK_Mode is

   type IMU_Data_Type is record
      Acc_X : Integer_16;
      Acc_Y : Integer_16;
      Acc_Z : Integer_16;
      Gyro_X : Integer_16;
      Gyro_Y : Integer_16;
      Gyro_Z : Integer_16;
   end record;

   --package IMU_Signal is new Gneric_Signal( IMU_Data_Type );
   --type Data_Type is new IMU_Signal.Sample_Type;


   package IMU_Sensor is new Generic_Sensor(IMU_Data_Type); use IMU_Sensor;

   type IMU_Tag is new IMU_Sensor.Sensor_Tag with record
      Freefall_Counter : Natural;
   end record;

   overriding procedure initialize (Self : in out IMU_Tag) with
   Global => (MPU6000.Driver.State);

   overriding procedure read_Measurement(Self : in out IMU_Tag) with
   Global => (MPU6000.Driver.State);

   procedure perform_Kalman_Filtering(Self : IMU_Tag; newAngle : Orientation_Type);

   function get_Linear_Acceleration(Self : IMU_Tag) return Linear_Acceleration_Vector;

   function get_Angular_Velocity(Self : IMU_Tag) return Angular_Velocity_Vector;

   function get_Orientation(Self : IMU_Tag) return Orientation_Type;

   function Fused_Orientation(Self : IMU_Tag; Orientation : Orientation_Type; Angular_Rate : Angular_Velocity_Vector) return Orientation_Type;

   procedure check_Freefall(Self : in out IMU_Tag; isFreefall : out Boolean);

   -- function get_Angular_Velocity (Self : IMU_Tag)


   Sensor : IMU_Tag;




end IMU;
