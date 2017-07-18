--  Data Watchpoint and Trace (DWT) Unit
--  Gives access to cycle counter.
pragma Restrictions (No_Elaboration_Code);

with Interfaces; use Interfaces;
with System;

package STM32.DWT is

   DWT_Core_Base : constant System.Address :=
     System'To_Address (16#E000_1000#);

   procedure Enable;
   procedure Disable;
   --  enable/disable overall DWT functionality

   procedure Enable_Cycle_Counter;
   procedure Enable_Sleep_Counter;

   procedure Disable_Cycle_Counter;
   procedure Disable_Sleep_Counter;

   function Read_Cycle_Counter return Unsigned_32;
   function Read_Sleep_Counter return Unsigned_8;

   type DWT_Ctrl_Register is record
      NUMCOMP        : HAL.Uint4;
      Reserved_23_27 : HAL.Uint5;
      CYCEVTENA      : Boolean;
      FOLDEVTENA     : Boolean;
      LSUEVTENA      : Boolean;
      SLEEPEVTENA    : Boolean;
      EXCEVTENA      : Boolean;
      CPIEVTENA      : Boolean;
      EXCTRCENA      : Boolean;
      Reserved_13_15 : HAL.Uint3;
      PCSAMPLEENA    : Boolean;
      SYNCTAP        : HAL.UInt2;
      CYCTAP         : Boolean;
      POSTCNT        : HAL.Uint4;
      POSTPRESET     : HAL.Uint4;
      CYCCNTENA      : Boolean;
   end record
     with Volatile_Full_Access, Size => 32,
       Bit_Order => System.Low_Order_First;

   for DWT_Ctrl_Register use record
      NUMCOMP        at 0 range 28 .. 31;
      Reserved_23_27 at 0 range 23 .. 27;
      CYCEVTENA      at 0 range 22 .. 22;
      FOLDEVTENA     at 0 range 21 .. 21;
      LSUEVTENA      at 0 range 20 .. 20;
      SLEEPEVTENA    at 0 range 19 .. 19;
      EXCEVTENA      at 0 range 18 .. 18;
      CPIEVTENA      at 0 range 17 .. 17;
      EXCTRCENA      at 0 range 16 .. 16;
      Reserved_13_15 at 0 range 13 .. 15;
      PCSAMPLEENA    at 0 range 12 .. 12;
      SYNCTAP        at 0 range 10 .. 11;
      CYCTAP         at 0 range  9 .. 9;
      POSTCNT        at 0 range  5 .. 8;
      POSTPRESET     at 0 range  1 .. 4;
      CYCCNTENA      at 0 range  0 .. 0;
   end record;

   ----------------
   -- DWT_Core_T --
   ----------------

   type DWT_Core_T is record
      DWT_CTRL     : DWT_Ctrl_Register;
      --  cycle count
      DWT_CYCCNT   : Word;
      --  additional cycles required to execute multi-cycle
      --  instructions and instruction fetch stalls
      DWT_CPICNT   : Byte; -- 8..31 reserved
      --  exception overhead (entry and exit) count
      DWT_EXCNT    : Byte; -- 8..31 reserved
      --  sleep count
      DWT_SLEEPCNT : Byte; -- 8..31 reserved
      --  cycles waiting for Load/Store to complete
      DWT_LSUCNT   : Byte; -- 8..31 reserved
      --  folded instruction count (saved cycles)
      DWT_FOLDCNT  : Byte; -- 8..31 reserved
      --  program counter sample reg
      DWT_PCSR     : Word;
      --  Comparator and Mask Registers
      DWT_COMP0    : Word;
      DWT_MASK0    : Word;
      DWT_FUNC0    : Word;
      DWT_COMP1    : Word;
      DWT_MASK1    : Word;
      DWT_FUNC1    : Word;
      DWT_COMP2    : Word;
      DWT_MASK2    : Word;
      DWT_FUNC2    : Word;
      DWT_COMP3    : Word;
      DWT_MASK3    : Word;
      DWT_FUNC4    : Word;
   end record
     with Volatile;

   for DWT_Core_T use record
      DWT_CTRL     at 0  range 0 .. 31;
      DWT_CYCCNT   at 4  range 0 .. 31;
      DWT_CPICNT   at 8  range 0 .. 7;
      DWT_EXCNT    at 12 range 0 .. 7;
      DWT_SLEEPCNT at 16 range 0 .. 7;
      DWT_LSUCNT   at 20 range 0 .. 7;
      DWT_FOLDCNT  at 24 range 0 .. 7;
      DWT_PCSR     at 28 range 0 .. 31;
      DWT_COMP0    at 32 range 0 .. 31;
      DWT_MASK0    at 36 range 0 .. 31;
      DWT_FUNC0    at 40 range 0 .. 31;
      --  there is an address jump
      DWT_COMP1    at 48 range 0 .. 31;
      DWT_MASK1    at 52 range 0 .. 31;
      DWT_FUNC1    at 56 range 0 .. 31;
      --  another address jump
      DWT_COMP2    at 64 range 0 .. 31;
      DWT_MASK2    at 68 range 0 .. 31;
      DWT_FUNC2    at 72 range 0 .. 31;
      --  another address jump
      DWT_COMP3    at 80 range 0 .. 31;
      DWT_MASK3    at 84 range 0 .. 31;
      DWT_FUNC4    at 88 range 0 .. 31;
      --  TODO: PID4..0
   end record;

   Core_DWT : aliased DWT_Core_T
     with Import, Address => DWT_Core_Base;
   --  Linker_Section => ".ccmdata"; --  pointer to CCM

end STM32.DWT;
