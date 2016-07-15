--  Institution: Technische Universität München
--  Department:  Realtime Computer Systems (RCS)
--  Project:     StratoX
--
--  Authors: Emanuel Regnath (emanuel.regnath@tum.de)
with HIL.Devices;

--  @summary
--  Target-independent specification for HIL of SPI
package HIL.SPI with
     Spark_Mode => On
     -- Abstract_State => Deselect 
is

   type Device_ID_Type is new HIL.Devices.Device_Type_SPI;

   type Data_Type is array (Natural range <>) of Byte;

   procedure configure;

   procedure select_Chip (Device : Device_ID_Type);

   procedure deselect_Chip (Device : Device_ID_Type); 
   -- with Global => (Input => (Deselect));

   procedure write (Device : Device_ID_Type; Data : Data_Type);
   --  send byte array to device
   
   procedure read (Device : in Device_ID_Type; Data : out Data_Type);
   --  read byte array from device

   procedure transfer
     (Device  : in     Device_ID_Type;
      Data_TX : in     Data_Type;
      Data_RX :    out Data_Type);
   --  combining sequential write and read, for those devices where CS must stay
   --  asserted between command and response.
   
   
   procedure transceive (Device : in Device_ID_Type; 
                         Data_TX : in Data_Type; 
                         Data_RX : out Data_Type) 
     with Pre => Data_TX'Length = Data_RX'Length;
   -- same as transfer, but simultanoeus read and write

end HIL.SPI;
