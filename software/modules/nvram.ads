--  Institution: Technische Universitaet Muenchen
--  Department:  Real-Time Computer Systems (RCS)
--  Project:     StratoX
--  Authors:     Martin Becker (becker@rcs.ei.tum.de)
with Interfaces; use Interfaces;

with HIL;

--  @summary
--  read/write from/to a non-volatile location. Every "variable"
--  has one byte. When the compilation date/time changed, all
--  variables are reset to their respective defaults. Otherwise
--  NVRAM keeps values across reboot/loss of power.
package NVRAM with SPARK_Mode,
   Abstract_State => Memory_State
is

   procedure Init;
   --  initialize this module and possibly underlying hardware

   procedure Self_Check (Status : out Boolean);
   --  check whether initialization was successful

   --  List of all variables stored in NVRAM. Add new ones when needed.
   type Variable_Name is (VAR_MISSIONSTATE,
                          VAR_BOOTCOUNTER,
                          VAR_EXCEPTION_LINE_L,
                          VAR_EXCEPTION_LINE_H,
                          VAR_EXCEPTION_ADDR_A,
                          VAR_EXCEPTION_ADDR_B,
                          VAR_EXCEPTION_ADDR_C,
                          VAR_EXCEPTION_ADDR_D,
                          VAR_START_TIME_A,
                          VAR_START_TIME_B,
                          VAR_START_TIME_C,
                          VAR_START_TIME_D,
                          VAR_HIGHWATERMARK_A, -- exec time of main loop in usec
                          VAR_HIGHWATERMARK_B,
                          VAR_HIGHWATERMARK_C,
                          VAR_HIGHWATERMARK_D,
                          VAR_HOME_HEIGHT_L,
                          VAR_HOME_HEIGHT_H,
                          VAR_GPS_TARGET_LONG_A,
                          VAR_GPS_TARGET_LONG_B,
                          VAR_GPS_TARGET_LONG_C,
                          VAR_GPS_TARGET_LONG_D,
                          VAR_GPS_TARGET_LAT_A,
                          VAR_GPS_TARGET_LAT_B,
                          VAR_GPS_TARGET_LAT_C,
                          VAR_GPS_TARGET_LAT_D,
                          VAR_GPS_TARGET_ALT_A,
                          VAR_GPS_TARGET_ALT_B,
                          VAR_GPS_TARGET_ALT_C,
                          VAR_GPS_TARGET_ALT_D,
                          VAR_GPS_LAST_LONG_A,
                          VAR_GPS_LAST_LONG_B,
                          VAR_GPS_LAST_LONG_C,
                          VAR_GPS_LAST_LONG_D,
                          VAR_GPS_LAST_LAT_A,
                          VAR_GPS_LAST_LAT_B,
                          VAR_GPS_LAST_LAT_C,
                          VAR_GPS_LAST_LAT_D,
                          VAR_GPS_LAST_ALT_A,
                          VAR_GPS_LAST_ALT_B,
                          VAR_GPS_LAST_ALT_C,
                          VAR_GPS_LAST_ALT_D,
                          VAR_GYRO_BIAS_X,
                          VAR_GYRO_BIAS_Y,
                          VAR_GYRO_BIAS_Z
                          );

   --  Default values for all variables (obligatory)
   type Defaults_Table is array (Variable_Name'Range) of HIL.Byte;
   Variable_Defaults : constant Defaults_Table :=
     (VAR_MISSIONSTATE => 0,
      VAR_BOOTCOUNTER  => 0,
      VAR_EXCEPTION_LINE_L => 0,
      VAR_EXCEPTION_LINE_H => 0,
      VAR_EXCEPTION_ADDR_A => 0,
      VAR_EXCEPTION_ADDR_B => 0,
      VAR_EXCEPTION_ADDR_C => 0,
      VAR_EXCEPTION_ADDR_D => 0,
      VAR_START_TIME_A => 0,
      VAR_START_TIME_B => 0,
      VAR_START_TIME_C => 0,
      VAR_START_TIME_D => 0,
      VAR_HIGHWATERMARK_A => 0,
      VAR_HIGHWATERMARK_B => 0,
      VAR_HIGHWATERMARK_C => 0,
      VAR_HIGHWATERMARK_D => 0,
      VAR_HOME_HEIGHT_L => 0,
      VAR_HOME_HEIGHT_H => 0,
      VAR_GPS_TARGET_LONG_A => 0,
      VAR_GPS_TARGET_LONG_B => 0,
      VAR_GPS_TARGET_LONG_C => 0,
      VAR_GPS_TARGET_LONG_D => 0,
      VAR_GPS_TARGET_LAT_A => 0,
      VAR_GPS_TARGET_LAT_B => 0,
      VAR_GPS_TARGET_LAT_C => 0,
      VAR_GPS_TARGET_LAT_D => 0,
      VAR_GPS_TARGET_ALT_A => 0,
      VAR_GPS_TARGET_ALT_B => 0,
      VAR_GPS_TARGET_ALT_C => 0,
      VAR_GPS_TARGET_ALT_D => 0,
      VAR_GPS_LAST_LONG_A => 0,
      VAR_GPS_LAST_LONG_B => 0,
      VAR_GPS_LAST_LONG_C => 0,
      VAR_GPS_LAST_LONG_D => 0,
      VAR_GPS_LAST_LAT_A => 0,
      VAR_GPS_LAST_LAT_B => 0,
      VAR_GPS_LAST_LAT_C => 0,
      VAR_GPS_LAST_LAT_D => 0,
      VAR_GPS_LAST_ALT_A => 0,
      VAR_GPS_LAST_ALT_B => 0,
      VAR_GPS_LAST_ALT_C => 0,
      VAR_GPS_LAST_ALT_D => 0,
      VAR_GYRO_BIAS_X => 20,  -- Bias in deci degree
      VAR_GYRO_BIAS_Y => 26,
      VAR_GYRO_BIAS_Z => 128-3+128    -- most evil hack ever
      );

   procedure Load (variable : in Variable_Name; data : out HIL.Byte);
   --  read variable with given name from NVRAM and return value

   procedure Load (variable : in Variable_Name; data : out Float)
     with Pre => Variable_Name'Pos (variable) < Variable_Name'Pos (Variable_Name'Last) - 3;
   --  same, but with Float convenience conversion. Point to first variable of the quadrupel.

   procedure Load (variable : in Variable_Name; data : out Unsigned_32)
     with Pre => Variable_Name'Pos (variable) < Variable_Name'Pos (Variable_Name'Last) - 3;
   --  same, but with U32 convenience conversion. Point to first variable of the quadrupel.

   procedure Store (variable : in Variable_Name; data : in HIL.Byte);
   --  write variable with given name to NVRAM.

   procedure Store (variable : in Variable_Name; data : in Float)
     with Pre => Variable_Name'Pos (variable) < Variable_Name'Pos (Variable_Name'Last) - 3;
   --  same, but with Float convenience conversion.  Point to first variable of the quadrupel.

   procedure Store (variable : in Variable_Name; data : in Unsigned_32)
     with Pre => Variable_Name'Pos (variable) < Variable_Name'Pos (Variable_Name'Last) - 3;
   --  same, but with U32 convenience conversion.  Point to first variable of the quadrupel.

   procedure Reset;
   --  explicit reset of NVRAM to defaults; same effect as re-compiling.

end NVRAM;
