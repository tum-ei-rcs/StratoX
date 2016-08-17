--  Based on AdaCore's Ada Drivers Library,
--  see https://github.com/AdaCore/Ada_Drivers_Library,
--  checkout 93b5f269341f970698af18f9182fac82a0be66c3.
--  Copyright (C) Adacore
--
--  Tailored to StratoX project.
--  Author: Martin Becker (becker@rcs.ei.tum.de)
with STM32_SVD.RCC; use STM32_SVD.RCC;

package body Media_Reader.SDCard.Config is

   -------------------------
   -- Enable_Clock_Device --
   -------------------------

   procedure Enable_Clock_Device
   is
   begin
      RCC_Periph.APB2ENR.SDIOEN := True;
   end Enable_Clock_Device;

   ------------------
   -- Reset_Device --
   ------------------

   procedure Reset_Device
   is
   begin
      RCC_Periph.APB2RSTR.SDIORST := True;
      -- FIXME: need some minimum time here?
      RCC_Periph.APB2RSTR.SDIORST := False;
   end Reset_Device;

end Media_Reader.SDCard.Config;
