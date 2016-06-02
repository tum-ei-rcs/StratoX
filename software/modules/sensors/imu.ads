

with MPU6000;
with Generic_Sensor;
with Interfaces; use Interfaces;


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


   package Sensor is new Generic_Sensor(IMU_Data_Type); use Sensor;

   type IMU_Tag is new Sensor.Sensor_Tag with record
      X : Integer;
   end record;

   overriding procedure initialize (Self : in out IMU_Tag);

   overriding procedure get_Data(Self : in out IMU_Tag; Data : out Sample_Type);

end IMU;
