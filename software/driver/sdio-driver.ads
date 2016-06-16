-- Project: Strato
-- System:  Stratosphere Balloon Flight Controller
-- Author: Martin Becker (becker@rcs.ei.tum.de)

-- @summary raw input and output to SD card
package SDIO.Driver is
   procedure init;
   -- initialize the interface

   procedure SDCard_Demo;
   -- example copied from AdaCore/Ada_Drivers_Library
end SDIO.Driver;
