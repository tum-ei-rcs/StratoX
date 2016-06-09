

with Generic_Sensor;

with Units.Navigation; use Units.Navigation;


package GPS is

   subtype GPS_Data_Type is GPS_Loacation_Type;

   package GPS_Sensor is new Generic_Sensor(GPS_Data_Type); use GPS_Sensor;

   type GPS_Tag is new GPS_Sensor.Sensor_Tag with record
      Protocol_UBX : Boolean;
   end record;

   overriding procedure initialize (Self : in out GPS_Tag);

   overriding procedure read_Measurement(Self : in out GPS_Tag);

   function get_Position(Self : GPS_Tag) return GPS_Data_Type;

   -- function get_Angular_Velocity (Self : GPS_Tag)


   Sensor : GPS_Tag;


end GPS;
