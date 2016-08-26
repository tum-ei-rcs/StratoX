package constants with SPARK_Mode is

   BUFLEN : constant := 200;

   type Arr_T is array (Natural range <>) of Integer;

   subtype Data_Type is Arr_T;
   subtype UBX_Data is Data_Type (0 .. 91);

   UBX_SYNC1 : constant := 16#B5#;
   UBX_SYNC2 : constant := 16#62#;

   procedure Do_Something;

end constants;
