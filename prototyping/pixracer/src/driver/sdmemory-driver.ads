--  Project: Strato
--  System:  Stratosphere Balloon Flight Controller
--  Author: Martin Becker (becker@rcs.ei.tum.de)

--  @summary read/write SD card using a file system

package SDMemory.Driver is
   procedure Init_Filesys;
   --  initialize the interface

   procedure List_Rootdir;
   --  example copied from AdaCore/Ada_Drivers_Library

   --  TODO: add file-style I/O procedures
end SDMemory.Driver;
