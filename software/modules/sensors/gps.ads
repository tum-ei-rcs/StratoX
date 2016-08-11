with Generic_Sensor;

with Units.Navigation; use Units.Navigation;
with Interfaces; use Interfaces;

package GPS with SPARK_Mode,
  Abstract_State => State
is

   subtype GPS_Data_Type is GPS_Loacation_Type;

   package GPS_Sensor is new Generic_Sensor(GPS_Data_Type); use GPS_Sensor;

   type GPS_Tag is new GPS_Sensor.Sensor_Tag with record
      Protocol_UBX : Boolean;
   end record;

   --overriding
   procedure initialize (Self : in out GPS_Tag);
     --with Global => (Output => GPS_Sensor.Sensor_State);

   --overriding
   procedure read_Measurement(Self : in out GPS_Tag);
     --with Global => (In_Out => GPS_Sensor.Sensor_State);

   function get_Position(Self : GPS_Tag) return GPS_Data_Type;

   function get_GPS_Fix(Self : GPS_Tag) return GPS_Fix_Type;

   function get_Num_Sats(Self : GPS_Tag) return Unsigned_8;

   -- function get_Angular_Velocity (Self : GPS_Tag)


   Sensor : GPS_Tag;


end GPS;
