--  Debug Exception and Monitor Control Register
pragma Restrictions (No_Elaboration_Code);

with Interfaces; use Interfaces;
with System;

package STM32.Debug is

   Debug_Core_Base : constant System.Address :=
     System'To_Address (16#E000_EDF0#);

   --------------------
   -- DEMCR_Register --
   --------------------

   type DEMCR_Register is record
      Reserved_25_31 : HAL.UInt7;
      TRCENA         : Boolean;
      Reserved_20_23 : HAL.UInt4;
      MON_REQ        : Boolean;
      MON_STEP       : Boolean;
      MON_PEND       : Boolean;
      MON_EN         : Boolean;
      Reserved_11_15 : HAL.Uint5;
      VC_HARDERR     : Boolean;
      VC_INTERR      : Boolean;
      VC_BUSERR      : Boolean;
      VC_STATERR     : Boolean;
      VC_CHKERR      : Boolean;
      VC_NOCPERR     : Boolean;
      VC_MMERR       : Boolean;
      Reserved_1_3   : HAL.Uint3;
      VC_CORERESET   : Boolean;
   end record
     with Volatile_Full_Access, Size => 32,
       Bit_Order => System.Low_Order_First;

   for DEMCR_Register use record
      Reserved_25_31 at 0 range 25 .. 31;
      TRCENA         at 0 range 24 .. 24;
      Reserved_20_23 at 0 range 20 .. 23;
      MON_REQ        at 0 range 19 .. 19;
      MON_STEP       at 0 range 18 .. 18;
      MON_PEND       at 0 range 17 .. 17;
      MON_EN         at 0 range 16 .. 16;
      Reserved_11_15 at 0 range 11 .. 15;
      VC_HARDERR     at 0 range 10 .. 10;
      VC_INTERR      at 0 range  9 .. 9;
      VC_BUSERR      at 0 range  8 .. 8;
      VC_STATERR     at 0 range  7 .. 7;
      VC_CHKERR      at 0 range  6 .. 6;
      VC_NOCPERR     at 0 range  5 .. 5;
      VC_MMERR       at 0 range  4 .. 4;
      Reserved_1_3   at 0 range  1 .. 3;
      VC_CORERESET   at 0 range  0 .. 0;
   end record;

   ------------------
   -- Core_Debug_T --
   ------------------

   type Core_Debug_T is record
      --  Debug halting control and status register (r+w)
      DHCSR : Word;
      --  Debug core register selector register (w)
      DCRSR : Word;
      --  Debug core register data register (r+w)
      DCRDR : Word;
      --  Debug Exception and Monitor Control Register (r+w)
      DEMCR : DEMCR_Register;
   end record
     with Volatile;

   for Core_Debug_T use record
      DHCSR at 0  range 0 .. 31;
      DCRSR at 4  range 0 .. 31; -- EDF4
      DCRDR at 8  range 0 .. 31; -- EDF8
      DEMCR at 12 range 0 .. 31; -- EDFC
   end record;

   Core_Debug : aliased Core_Debug_T
     with Import, Address => Debug_Core_Base;

end STM32.Debug;
