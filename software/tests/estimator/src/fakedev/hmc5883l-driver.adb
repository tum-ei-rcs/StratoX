with Simulation;
with Ada.Text_IO; use Ada.Text_IO;

package body hmc5883l.driver with
Refined_State => (State => (buffer, mode))
is

   procedure initialize is null;

   function testConnection return Boolean is (True);

   -- CONFIG_A register
   function getSampleAveraging return Unsigned_8  is
   begin
      -- TODO
      return 0;
   end;
   procedure setSampleAveraging(averaging : Unsigned_8) is
   begin
      -- TODO
      null;
   end;
   procedure getDataRate(rate : out Unsigned_8) is
   begin
      -- TODO
      null;
   end;
   procedure setDataRate(rate : Unsigned_8) is
   begin
      -- TODO
      null;
   end;
   procedure getMeasurementBias(bias : out Unsigned_8) is
   begin
      -- TODO
      null;
   end;
   procedure setMeasurementBias(bias : Unsigned_8) is
   begin
      -- TODO
      null;
   end;

   -- CONFIG_B register
   procedure getGain(gain : out Unsigned_8) is
   begin
      -- TODO
      null;
   end;
   procedure setGain(gain : Unsigned_8) is
   begin
      -- TODO
      null;
   end;

   -- MODE register
   procedure getMode(mode : out Unsigned_8) is
   begin
      -- TODO
      null;
   end;
   procedure setMode(newMode : Unsigned_8) is
   begin
      -- TODO
      null;
   end;

   -- DATA* registers
   procedure getHeading(x : out Integer_16; y : out Integer_16; z : out Integer_16) is
      SCALE_MAG : constant := 1.0e6; -- Tesla -> microtesla (raw data is uT)
   begin
      x := Integer_16 (Simulation.CSV_here.Get_Column ("magX") * SCALE_MAG);
      y := Integer_16 (Simulation.CSV_here.Get_Column ("magY") * SCALE_MAG);
      z := Integer_16 (Simulation.CSV_here.Get_Column ("magZ") * SCALE_MAG);
      null;
   end;

   procedure getHeadingX(x : out Integer_16) is
   begin
      null; -- TODO
   end;
   procedure getHeadingY(y : out Integer_16) is
   begin
      null; -- TODO
   end;
   procedure getHeadingZ(z : out Integer_16) is
   begin
      null; -- TODO
   end;

   -- STATUS register
   function getLockStatus return Boolean is (False);
   function getReadyStatus return Boolean is (True);

   -- ID* registers
   function getIDA return Unsigned_8 is
   begin
      return 0; -- todo
   end;
   function getIDB return Unsigned_8 is
   begin
      return 0; -- todo
   end;
   function getIDC return Unsigned_8 is
   begin
      return 0; -- todo
   end;

end hmc5883l.driver;
