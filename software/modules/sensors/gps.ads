with Generic_Sensor;

with Units;
with Units.Navigation; use Units.Navigation;
with Interfaces; use Interfaces;
with ublox8.Driver;

package GPS with SPARK_Mode,
  Abstract_State => State
is

   subtype GPS_Data_Type is GPS_Loacation_Type;

   subtype GPS_DateTime is ublox8.Driver.GPS_DateTime_Type;

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

   function get_Pos_Accuracy(Self : GPS_Tag) return Units.Length_Type;

   function get_Speed(Self : GPS_Tag) return Units.Linear_Velocity_Type;

   function get_Time(Self : GPS_Tag) return GPS_DateTime;

   -- function get_Angular_Velocity (Self : GPS_Tag)

   function Image (tm : GPS_DateTime) return String
     with Post => Image'Result'Length <= 60;

   Sensor : GPS_Tag;


end GPS;
