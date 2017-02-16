package body HIL.SPI is

   procedure configure is null;

   procedure select_Chip (Device : Device_ID_Type) is null;

   procedure deselect_Chip (Device : Device_ID_Type) is null;
   -- with Global => (Input => (Deselect));

   procedure write (Device : Device_ID_Type; Data : Data_Type) is null;
   --  send byte array to device

   procedure read (Device : in Device_ID_Type; Data : out Data_Type) is null;
   --  read byte array from device

   procedure transfer
     (Device  : in     Device_ID_Type;
      Data_TX : in     Data_Type;
      Data_RX :    out Data_Type) is null;
   --  combining sequential write and read, for those devices where CS must stay
   --  asserted between command and response.


   procedure transceive (Device : in Device_ID_Type;
                         Data_TX : in Data_Type;
                         Data_RX : out Data_Type) is null;
end HIL.SPI;
