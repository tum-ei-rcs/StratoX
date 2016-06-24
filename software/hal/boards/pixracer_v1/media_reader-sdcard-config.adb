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
