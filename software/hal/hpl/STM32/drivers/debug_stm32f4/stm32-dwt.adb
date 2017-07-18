--  Data Watchpoint and Trace (DWT) Unit
--  Gives access to cycle counter.
with STM32.Debug;  use STM32.Debug;

package body STM32.DWT is

   ------------
   -- Enable --
   ------------

   procedure Enable is
   begin
      Core_Debug.DEMCR.TRCENA := True;
   end Enable;

   ------------
   -- Disable --
   ------------

   procedure Disable is
   begin
      Core_Debug.DEMCR.TRCENA := False;
   end Disable;

   --------------------------
   -- Enable_Cycle_Counter --
   --------------------------

   procedure Enable_Cycle_Counter is
   begin
      Enable;
      Core_DWT.DWT_CYCCNT := 0;
      Core_DWT.DWT_CTRL.CYCCNTENA := True;
   end Enable_Cycle_Counter;

   ---------------------------
   -- Disable_Cycle_Counter --
   ---------------------------

   procedure Disable_Cycle_Counter is
   begin
      Core_DWT.DWT_CTRL.CYCCNTENA := False;
   end Disable_Cycle_Counter;

   --------------------------
   -- Enable_Sleep_Counter --
   --------------------------

   procedure Enable_Sleep_Counter is
   begin
      Enable;
      Core_DWT.DWT_SLEEPCNT := 0;
      Core_DWT.DWT_CTRL.SLEEPEVTENA := True;
   end Enable_Sleep_Counter;

   ---------------------------
   -- Disable_Sleep_Counter --
   ---------------------------

   procedure Disable_Sleep_Counter is
   begin
      Core_DWT.DWT_CTRL.SLEEPEVTENA := False;
   end Disable_Sleep_Counter;

   ------------------------
   -- Read_Cycle_Counter --
   ------------------------

   function Read_Cycle_Counter return Unsigned_32 is
     (Unsigned_32 (Core_DWT.DWT_CYCCNT));

   ------------------------
   -- Read_Sleep_Counter --
   ------------------------

   function Read_Sleep_Counter return Unsigned_8 is
     (Unsigned_8 (Core_DWT.DWT_SLEEPCNT));

end STM32.DWT;
