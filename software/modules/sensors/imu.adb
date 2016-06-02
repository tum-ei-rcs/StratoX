
package body IMU is

   procedure initialize (Self : in out IMU_Tag) is 
   begin 
      Self.state := READY;
   end initialize;

   procedure get_Data(Self : in out IMU_Tag; Data : out Sample_Type) is
   begin
      null;
   end get_Data;
   

end IMU;
