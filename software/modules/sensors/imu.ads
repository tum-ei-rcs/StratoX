with Generic_Sensor;
with Interfaces; use Interfaces;

with Units; use Units;
with Units.Vectors; use Units.Vectors;
with Units.Navigation; use Units.Navigation;

package IMU with
SPARK_Mode,
  Abstract_State => State
is

   --  this is how data from the IMU looks like
   type IMU_Data_Type is record
      Acc_X : Integer_16 := 0;
      Acc_Y : Integer_16 := 0;
      Acc_Z : Integer_16 := 0;
      Gyro_X : Integer_16 := 0;
      Gyro_Y : Integer_16 := 0;
      Gyro_Z : Integer_16 := 0;
   end record;

   package IMU_Sensor is new Generic_Sensor(IMU_Data_Type);
   use IMU_Sensor;


   --package IMU_Signal is new Gneric_Signal( IMU_Data_Type );
   --type Data_Type is new IMU_Signal.Sample_Type;



   type IMU_Tag is new IMU_Sensor.Sensor_Tag with record -- inherit the sensor tag and extend record.
      Freefall_Counter : Natural;
   end record;

--     package bar with Initializes => IMU_Sensor.Sensor_State is
--        foo : Integer := 0;
--     end bar;
--
   --overriding
   procedure initialize (Self : in out IMU_Tag);
     --with Global => (Output => IMU_Sensor.Sensor_State);
   -- with Global => (Input => (MPU6000.Driver.State, Ada.Real_Time.Clock_Time), In_Out => IMU.State);

   --overriding
   procedure read_Measurement(Self : in out IMU_Tag);
   --with Global => (In_Out => IMU_Sensor.Sensor_State);
   --  with Global => (MPU6000.Driver.State);

   procedure perform_Kalman_Filtering(Self : IMU_Tag; newAngle : Orientation_Type);

   function get_Linear_Acceleration(Self : IMU_Tag) return Linear_Acceleration_Vector;

   function get_Angular_Velocity(Self : IMU_Tag) return Angular_Velocity_Vector;

   function get_Orientation(Self : IMU_Tag) return Orientation_Type;

   procedure Fused_Orientation(Self : IMU_Tag; Orientation : Orientation_Type;
                               Angular_Rate : Angular_Velocity_Vector;
                               result : out Orientation_Type);

   procedure check_Freefall(Self : in out IMU_Tag; isFreefall : out Boolean);

   -- function get_Angular_Velocity (Self : IMU_Tag)

   --  FIXME: why is this private:?
   Sensor : IMU_Tag;-- with Part_Of => State;

end IMU;
