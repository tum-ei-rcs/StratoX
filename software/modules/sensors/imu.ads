

with Generic_Sensor;
with Interfaces; use Interfaces;

with Units.Vectors; use Units.Vectors;


package IMU is

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

   type IMU_Tag is new IMU_Sensor.Sensor_Tag with null record;

   overriding procedure initialize (Self : in out IMU_Tag);

   overriding procedure read_Measurement(Self : in out IMU_Tag);

   function get_Linear_Acceleration(Self : IMU_Tag) return Linear_Acceleration_Vector;

   -- function get_Angular_Velocity (Self : IMU_Tag)


   Sensor : IMU_Tag;




end IMU;
