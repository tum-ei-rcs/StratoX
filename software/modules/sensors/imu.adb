

with MPU6000.Driver; use MPU6000;

with Units; use Units;

package body IMU is

   G_Freefall_Counter : Natural := 0;

   function MPU_To_PX4Frame(vector : Linear_Acceleration_Vector) return Linear_Acceleration_Vector is
      ( ( X => vector(Y), Y => -vector(X), Z => vector(Z) ) );


   overriding
   procedure initialize (Self : in out IMU_Tag) is
   begin 
      
      if MPU6000.Driver.Test_Connection then
         Driver.Init;
         Self.state := READY;
      else
         Self.state := ERROR;
      end if;
   end initialize;

   overriding
   procedure read_Measurement(Self : in out IMU_Tag) is
   begin
      Driver.Get_Motion_6(Self.sample.data.Acc_X,
                          Self.sample.data.Acc_Y,
                          Self.sample.data.Acc_Z,
                          Self.sample.data.Gyro_X,
                          Self.sample.data.Gyro_Y,
                          Self.sample.data.Gyro_Z);    
   end read_Measurement;
   
   
   function get_Linear_Acceleration(Self : IMU_Tag) return Linear_Acceleration_Vector is
      result : Linear_Acceleration_Vector;
      sensitivity : constant Float := Driver.MPU6000_G_PER_LSB_2;
   begin
      result := ( X => Unit_Type( Float( Self.sample.data.Acc_X ) * sensitivity ) * GRAVITY,
                  Y => Unit_Type( Float( Self.sample.data.Acc_Y ) * sensitivity ) * GRAVITY,
                  Z => Unit_Type( Float( Self.sample.data.Acc_Z ) * sensitivity ) * GRAVITY );
      result := MPU_To_PX4Frame( result );
      return result;
   end get_Linear_Acceleration;


   procedure check_Freefall(Self : in out IMU_Tag; isFreefall : out Boolean) is
   begin
      if abs ( Units.Vectors.Cartesian_Vector_Type( get_Linear_Acceleration(Self) ) ) < Unit_Type( 0.5 ) then
         Self.Freefall_Counter := Self.Freefall_Counter + 1;
      else 
         Self.Freefall_Counter := 0;
      end if;
      isFreefall := (Self.Freefall_Counter >= 5);
   end check_Freefall;





end IMU;
