-- Project: Strato
-- System:  Stratosphere Balloon Flight Controller
-- Author: Martin Becker (becker@rcs.ei.tum.de)
with SDMemory.Driver;

-- @summary top-level package for reading/writing to SD card
package body SDMemory is
   procedure Init is
   begin
      SDMemory.Driver.Init_Filesys;
   end Init;
end SDMemory;
