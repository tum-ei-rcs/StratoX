

with Generic_Sensor;

with Units.Vectors; use Units.Vectors;


package GPS is

   type Longitude_Type is new Units.Angle_Type range -180.0 .. 180.0;
   type Latitude_Type is new Units.Angle_Type range -90.0 .. 90.0;
   type Altitute_Type is new Units.Length_Type range -10.0 .. 10_000.0;

   type GPS_Data_Type is record
      Longitude : Longitude_Type;
      Latitude  : Latitude_Type;
      Altitute  : Altitute_Type;
   end record;

   --package GPS_Signal is new Gneric_Signal( GPS_Data_Type );
   --type Data_Type is new GPS_Signal.Sample_Type;


   package GPS_Sensor is new Generic_Sensor(GPS_Data_Type); use GPS_Sensor;

   type GPS_Tag is new GPS_Sensor.Sensor_Tag with record
      Protocol_UBX : Boolean;
   end record;

   overriding procedure initialize (Self : in out GPS_Tag);

   overriding procedure read_Measurement(Self : in out GPS_Tag);

   function get_Linear_Velocity(Self : GPS_Tag) return Linear_Acceleration_Vector;

   -- function get_Angular_Velocity (Self : GPS_Tag)


   Sensor : GPS_Tag;


end GPS;
