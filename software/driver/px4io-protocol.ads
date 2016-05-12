--***************************************************************************
--
--   Copyright (c)2_0122_014 PX4 Development Team. All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in
--    the documentation and/or other materials provided with the
--    distribution.
-- 3. Neither the name PX4 nor the names of its contributors may be
--    used to endorse or promote products derived from this software
--    without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-- LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
-- FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
-- COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
-- BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
-- OF USE, DATA, PROFITS : OR; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
-- AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
-- ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
--**************************************************************************


-- with Interfaces; use Interfaces;

package PX4IO.Protocol is


--*
-- @file protocol.h
--
-- PX4IO interface protocol.
--
-- Communication is performed via writes to and reads from 16-bit virtual
-- registers organised into pages of 255 registers each.
--
-- The first two bytes of each write select a page and offset address
-- respectively. Subsequent reads and writes increment the offset within
-- the page.
--
-- Some pages are read- or write-only.
--
-- Note that some pages may permit offset values greater than 255, which
-- can only be achieved by long writes. The offset does not wrap.
--
-- Writes to unimplemented registers are ignored. Reads from unimplemented
-- registers return undefined values.
--
-- As convention, values that would be floating point in other parts of
-- the PX4 system are expressed as signed integer values scaled by10_000,
-- e.g. control values range from 10_000..10000.  Use the REG_TO_SIGNED and
-- SIGNED_TO_REG macros to convert between register representation and
-- the signed version, and REG_TO_FLOAT/FLOAT_TO_REG to convert to Float.
--
-- Note that the implementation of readable pages prefers registers within
-- readable pages to be densely packed. Page numbers do not need to be
-- packed.
--
-- Definitions marked [1] are only valid on PX4IOv1 boards. Likewise,
-- [2] denotes definitions specific to the PX4IOv2 board.
--

-- Per C, this is safe for all 2's complement systems
-- REG_TO_SIGNED : constant := (reg)	(Integer_16(reg));
-- SIGNED_TO_REG : constant := (signed)	(Unsigned_16(signed));
--
-- REG_TO_FLOAT : constant := (reg)	(FloatREG_TO_SIGNED(reg) /10_000.0f);
-- FLOAT_TO_REG : constant := Float	SIGNED_TO_REG(Integer_16(Float *10_000.0f));

type Unsigned_16 is mod 2**16;
type Unsigned_8  is mod 2**8;

type Page_Type is new Unsigned_8;
type Offset_Type is new Unsigned_8;
subtype Bit_Mask_Type is Unsigned_8;




function Shift_Left(This : Integer; Shift : Integer) return Bit_Mask_Type is
( 2**Shift );





PX4IO_PROTOCOL_VERSION : constant := 4;

-- maximum allowable sizes on this protocol version
PX4IO_PROTOCOL_MAX_CONTROL_COUNT : constant := 8; --*< The protocol does not support more than set here, individual units might support less - see PX4IO_P_CONFIG_CONTROL_COUNT

-- static configuration page
PX4IO_PAGE_CONFIG : constant := 0;
PX4IO_P_CONFIG_PROTOCOL_VERSION : constant := 0;   -- PX4IO_PROTOCOL_VERSION
PX4IO_P_CONFIG_HARDWARE_VERSION : constant := 1;   -- magic numbers TBD
PX4IO_P_CONFIG_BOOTLOADER_VERSION : constant := 2; -- get this how?
PX4IO_P_CONFIG_MAX_TRANSFER : constant := 3;       -- maximum I2C transfer size
PX4IO_P_CONFIG_CONTROL_COUNT : constant := 4;      -- hardcoded max control count supported
PX4IO_P_CONFIG_ACTUATOR_COUNT : constant := 5;     -- hardcoded max actuator output count
PX4IO_P_CONFIG_RC_INPUT_COUNT : constant := 6;     -- hardcoded max R/C input count supported
PX4IO_P_CONFIG_ADC_INPUT_COUNT : constant := 7;    -- hardcoded max ADC inputs
PX4IO_P_CONFIG_RELAY_COUNT : constant := 8;        -- hardcoded # of relay outputs

-- dynamic status page
PX4IO_PAGE_STATUS : constant := 1;
PX4IO_P_STATUS_FREEMEM : constant := 0;
PX4IO_P_STATUS_CPULOAD : constant := 1;

PX4IO_P_STATUS_FLAGS : constant := 2	 ;-- monitoring flags
PX4IO_P_STATUS_FLAGS_OUTPUTS_ARMED : constant Bit_Mask_Type := (Shift_Left(1, 0)) ;-- arm-ok and locally armed
PX4IO_P_STATUS_FLAGS_OVERRIDE : constant Bit_Mask_Type := (Shift_Left(1, 1)) ;-- in manual override
PX4IO_P_STATUS_FLAGS_RC_OK : constant Bit_Mask_Type := (Shift_Left(1, 2)) ;-- RC input is valid
PX4IO_P_STATUS_FLAGS_RC_PPM : constant Bit_Mask_Type := (Shift_Left(1, 3)) ;-- PPM input is valid
PX4IO_P_STATUS_FLAGS_RC_DSM : constant Bit_Mask_Type := (Shift_Left(1, 4)) ;-- DSM input is valid
PX4IO_P_STATUS_FLAGS_RC_SBUS : constant Bit_Mask_Type := (Shift_Left(1, 5)) ;-- SBUS input is valid
PX4IO_P_STATUS_FLAGS_FMU_OK : constant Bit_Mask_Type := (Shift_Left(1, 6)) ;-- controls from FMU are valid
PX4IO_P_STATUS_FLAGS_RAW_PWM : constant Bit_Mask_Type := (Shift_Left(1, 7)) ;-- raw PWM from FMU is bypassing the mixer
PX4IO_P_STATUS_FLAGS_MIXER_OK : constant Bit_Mask_Type := (Shift_Left(1, 8)) ;-- mixer is OK
PX4IO_P_STATUS_FLAGS_ARM_SYNC : constant Bit_Mask_Type := (Shift_Left(1, 9)) ;-- the arming state between IO and FMU is in sync
PX4IO_P_STATUS_FLAGS_INIT_OK : constant Bit_Mask_Type := (Shift_Left(1, 10)) ;-- initialisation of the IO completed without error
PX4IO_P_STATUS_FLAGS_FAILSAFE : constant Bit_Mask_Type := (Shift_Left(1, 11)) ;-- failsafe is active
PX4IO_P_STATUS_FLAGS_SAFETY_OFF : constant Bit_Mask_Type := (Shift_Left(1, 12)) ;-- safety is off
PX4IO_P_STATUS_FLAGS_FMU_INITIALIZED : constant Bit_Mask_Type := (Shift_Left(1, 13)) ;-- FMU was initialized and OK once
PX4IO_P_STATUS_FLAGS_RC_ST24 : constant Bit_Mask_Type := (Shift_Left(1, 14)) ;-- ST24 input is valid
PX4IO_P_STATUS_FLAGS_RC_SUMD : constant Bit_Mask_Type := (Shift_Left(1, 15)) ;-- SUMD input is valid

PX4IO_P_STATUS_ALARMS : constant Bit_Mask_Type := 3	 ;-- alarm flags - alarms latch, write 1 to a bit to clear it
PX4IO_P_STATUS_ALARMS_VBATT_LOW : constant Bit_Mask_Type := (Shift_Left(1, 0)) ;-- [1] VBatt is very close to regulator dropout
PX4IO_P_STATUS_ALARMS_TEMPERATURE : constant Bit_Mask_Type := (Shift_Left(1, 1)) ;-- board temperature is high
PX4IO_P_STATUS_ALARMS_SERVO_CURRENT : constant Bit_Mask_Type := (Shift_Left(1, 2)) ;-- [1] servo current limit was exceeded
PX4IO_P_STATUS_ALARMS_ACC_CURRENT : constant Bit_Mask_Type := (Shift_Left(1, 3)) ;-- [1] accessory current limit was exceeded
PX4IO_P_STATUS_ALARMS_FMU_LOST : constant Bit_Mask_Type := (Shift_Left(1, 4)) ;-- timed out waiting for controls from FMU
PX4IO_P_STATUS_ALARMS_RC_LOST : constant Bit_Mask_Type := (Shift_Left(1, 5)) ;-- timed out waiting for RC input
PX4IO_P_STATUS_ALARMS_PWM_ERROR : constant Bit_Mask_Type := (Shift_Left(1, 6)) ;-- PWM configuration or output was bad
PX4IO_P_STATUS_ALARMS_VSERVO_FAULT : constant Bit_Mask_Type := (Shift_Left(1, 7)) ;-- [2] VServo was out of the valid range (2.5 - 5.5 V)

PX4IO_P_STATUS_VBATT : constant := 4	;-- [1] battery voltage in mV
PX4IO_P_STATUS_IBATT : constant := 5	;-- [1] battery current (ADC : raw)
PX4IO_P_STATUS_VSERVO : constant := 6	;-- [2] servo rail voltage in mV
PX4IO_P_STATUS_VRSSI : constant := 7	;-- [2] RSSI voltage
PX4IO_P_STATUS_PRSSI : constant := 8	;-- [2] RSSI PWM value

PX4IO_P_STATUS_MIXER : constant := 9	 ;-- mixer actuator limit flags
PX4IO_P_STATUS_MIXER_LOWER_LIMIT : constant Bit_Mask_Type := (Shift_Left(1, 0)) ;--*< at least one actuator output has reached lower limit
PX4IO_P_STATUS_MIXER_UPPER_LIMIT : constant Bit_Mask_Type := (Shift_Left(1, 1)) ;--*< at least one actuator output has reached upper limit
PX4IO_P_STATUS_MIXER_YAW_LIMIT : constant Bit_Mask_Type := (Shift_Left(1, 2)) ;--*< yaw control is limited because it causes output clipping

-- array of post-mix actuator outputs, 10_000..10000
PX4IO_PAGE_ACTUATORS : constant := 2		;-- 0..CONFIG_ACTUATOR_COUNT-1

-- array of PWM servo output values, microseconds
PX4IO_PAGE_SERVOS : constant := 3		;-- 0..CONFIG_ACTUATOR_COUNT-1

-- array of raw RC input values, microseconds
PX4IO_PAGE_RAW_RC_INPUT : constant := 4;
PX4IO_P_RAW_RC_COUNT : constant := 0	;-- number of valid channels
PX4IO_P_RAW_RC_FLAGS : constant := 1	;-- RC detail status flags
PX4IO_P_RAW_RC_FLAGS_FRAME_DROP : constant Bit_Mask_Type := (Shift_Left(1, 0)) ;-- single frame drop
PX4IO_P_RAW_RC_FLAGS_FAILSAFE : constant Bit_Mask_Type := (Shift_Left(1, 1)) ;-- receiver is in failsafe mode
PX4IO_P_RAW_RC_FLAGS_RC_DSM11 : constant Bit_Mask_Type := (Shift_Left(1, 2)) ;-- DSM decoding is 11 bit mode
PX4IO_P_RAW_RC_FLAGS_MAPPING_OK : constant Bit_Mask_Type := (Shift_Left(1, 3)) ;-- Channel mapping is ok
PX4IO_P_RAW_RC_FLAGS_RC_OK : constant Bit_Mask_Type := (Shift_Left(1, 4)) ;-- RC reception ok

PX4IO_P_RAW_RC_NRSSI : constant := 2	;-- [2] Normalized RSSI value, 0: no reception, 255: perfect reception
PX4IO_P_RAW_RC_DATA : constant := 3	;-- [1] + [2] Details about the RC source (PPM frame length, Spektrum protocol type)
PX4IO_P_RAW_FRAME_COUNT : constant := 4	;-- Number of total received frames (counter : wrapping)
PX4IO_P_RAW_LOST_FRAME_COUNT : constant := 5	;-- Number of total dropped frames (counter : wrapping)
PX4IO_P_RAW_RC_BASE : constant := 6	;-- CONFIG_RC_INPUT_COUNT channels from here

-- array of scaled RC input values, 10_000..10000
PX4IO_PAGE_RC_INPUT : constant := 5;
PX4IO_P_RC_VALID : constant := 0	;-- bitmask of valid controls
PX4IO_P_RC_BASE : constant := 1	;-- CONFIG_RC_INPUT_COUNT controls from here

-- array of raw ADC values
PX4IO_PAGE_RAW_ADC_INPUT : constant := 6		;-- 0..CONFIG_ADC_INPUT_COUNT-1

-- PWM servo information
PX4IO_PAGE_PWM_INFO : constant := 7;
PX4IO_RATE_MAP_BASE : constant := 0	;-- 0..CONFIG_ACTUATOR_COUNT bitmaps of PWM rate groups

-- setup page
PX4IO_PAGE_SETUP : constant := 50;
PX4IO_P_SETUP_FEATURES : constant := 0;
PX4IO_P_SETUP_FEATURES_SBUS1_OUT : constant Bit_Mask_Type := (Shift_Left(1, 0)) ;--*< enable S.Bus v1 output
PX4IO_P_SETUP_FEATURES_SBUS2_OUT : constant Bit_Mask_Type := (Shift_Left(1, 1)) ;--*< enable S.Bus v2 output
PX4IO_P_SETUP_FEATURES_PWM_RSSI : constant Bit_Mask_Type := (Shift_Left(1, 2)) ;--*< enable PWM RSSI parsing
PX4IO_P_SETUP_FEATURES_ADC_RSSI : constant Bit_Mask_Type := (Shift_Left(1, 3)) ;--*< enable ADC RSSI parsing

PX4IO_P_SETUP_ARMING : constant := 1	 ;-- arming controls
PX4IO_P_SETUP_ARMING_IO_ARM_OK : constant Bit_Mask_Type := (Shift_Left(1, 0)) ;-- OK to arm the IO side
PX4IO_P_SETUP_ARMING_FMU_ARMED : constant Bit_Mask_Type := (Shift_Left(1, 1)) ;-- FMU is already armed
PX4IO_P_SETUP_ARMING_MANUAL_OVERRIDE_OK : constant Bit_Mask_Type := (Shift_Left(1, 2)) ;-- OK to switch to manual override via override RC channel
PX4IO_P_SETUP_ARMING_FAILSAFE_CUSTOM : constant Bit_Mask_Type := (Shift_Left(1, 3)) ;-- use custom failsafe values, not 0 values of mixer
PX4IO_P_SETUP_ARMING_INAIR_RESTART_OK : constant Bit_Mask_Type := (Shift_Left(1, 4)) ;-- OK to try in-air restart
PX4IO_P_SETUP_ARMING_ALWAYS_PWM_ENABLE : constant Bit_Mask_Type := (Shift_Left(1, 5)) ;-- Output of PWM right after startup enabled to help ESCs initialize and prevent them from beeping
PX4IO_P_SETUP_ARMING_RC_HANDLING_DISABLED : constant Bit_Mask_Type := (Shift_Left(1, 6)) ;-- Disable the IO-internal evaluation of the RC
PX4IO_P_SETUP_ARMING_LOCKDOWN : constant Bit_Mask_Type := (Shift_Left(1, 7)) ;-- If set, the system operates normally, but won't actuate any servos
PX4IO_P_SETUP_ARMING_FORCE_FAILSAFE : constant Bit_Mask_Type := (Shift_Left(1, 8)) ;-- If set, the system will always output the failsafe values
PX4IO_P_SETUP_ARMING_TERMINATION_FAILSAFE : constant Bit_Mask_Type := (Shift_Left(1, 9)) ;-- If set, the system will never return from a failsafe, but remain in failsafe once triggered.
PX4IO_P_SETUP_ARMING_OVERRIDE_IMMEDIATE : constant Bit_Mask_Type := (Shift_Left(1, 10)) ;-- If set then on FMU failure override is immediate. Othewise it waits for the mode switch to go past the override thrshold

PX4IO_P_SETUP_PWM_RATES : constant := 2	;-- bitmask, 0 := low rate, 1 := high rate
PX4IO_P_SETUP_PWM_DEFAULTRATE : constant := 3	;-- 'low' PWM frame output rate in Hz
PX4IO_P_SETUP_PWM_ALTRATE : constant := 4	;-- 'high' PWM frame output rate in Hz


PX4IO_P_SETUP_RELAYS_PAD : constant := 5;


PX4IO_P_SETUP_VBATT_SCALE : constant := 6	;-- hardware rev [1] battery voltage correction factor Float
PX4IO_P_SETUP_VSERVO_SCALE : constant := 6	;-- hardware rev [2] servo voltage correction factor Float
PX4IO_P_SETUP_DSM : constant := 7	;-- DSM bind state

type PX4IO_DSM_Bind_Type is (							-- DSM bind states
	dsm_bindpower_down,
	dsm_bindpower_up,
	dsm_bind_set_rx_out,
	dsm_bind_sendpulses,
	dsm_bind_reinit_uart
);

-- 8
PX4IO_P_SETUP_SET_DEBUG : constant := 9	;-- debug level for IO board

PX4IO_P_SETUP_REBOOT_BL : constant := 10	;-- reboot IO into bootloader
PX4IO_REBOOT_BL_MAGIC : constant :=14_662	;-- required argument for reboot (random)

PX4IO_P_SETUP_CRC : constant := 11	;-- get CRC of IO firmware
-- storage space of 12 occupied by CRC
PX4IO_P_SETUP_FORCE_SAFETY_OFF : constant := 12	;-- force safety switch into
	--'armed' (enabled : PWM) state - this is a non-data write and
	--hence index 12 can safely be used.
PX4IO_P_SETUP_RC_THR_FAILSAFE_US : constant := 13	;--*< the throttle failsafe pulse length in microseconds

PX4IO_P_SETUP_FORCE_SAFETY_ON : constant := 14	;-- force safety switch into 'disarmed' (PWM disabled state)
PX4IO_FORCE_SAFETY_MAGIC : constant :=22_027	;-- required argument for force safety (random)

PX4IO_P_SETUP_PWM_REVERSE : constant := 15	;--*< Bitmask to reverse PWM channels 1-8
PX4IO_P_SETUP_TRIM_ROLL : constant := 16	;--*< Roll trim, in actuator units
PX4IO_P_SETUP_TRIM_PITCH : constant := 17	;--*< Pitch trim, in actuator units
PX4IO_P_SETUP_TRIM_YAW : constant := 18	;--*< Yaw trim, in actuator units

PX4IO_P_SETUP_SBUS_RATE : constant := 19	;-- frame rate of SBUS1 output in Hz

-- autopilot control values, 10_000..10000
PX4IO_PAGE_CONTROLS : constant := 51	;--*< actuator control groups, one after the other, 8 wide
PX4IO_P_CONTROLS_GROUP_0 : constant := (PX4IO_PROTOCOL_MAX_CONTROL_COUNT * 0)	;--*< 0..PX4IO_PROTOCOL_MAX_CONTROL_COUNT - 1
PX4IO_P_CONTROLS_GROUP_1 : constant := (PX4IO_PROTOCOL_MAX_CONTROL_COUNT * 1)	;--*< 0..PX4IO_PROTOCOL_MAX_CONTROL_COUNT - 1
PX4IO_P_CONTROLS_GROUP_2 : constant := (PX4IO_PROTOCOL_MAX_CONTROL_COUNT * 2)	;--*< 0..PX4IO_PROTOCOL_MAX_CONTROL_COUNT - 1
PX4IO_P_CONTROLS_GROUP_3 : constant := (PX4IO_PROTOCOL_MAX_CONTROL_COUNT * 3)	;--*< 0..PX4IO_PROTOCOL_MAX_CONTROL_COUNT - 1

PX4IO_P_CONTROLS_GROUP_VALID : constant := 64;
PX4IO_P_CONTROLS_GROUP_VALID_GROUP0 : constant Bit_Mask_Type := (Shift_Left(1, 0)) ;--*< group 0 is valid / received
PX4IO_P_CONTROLS_GROUP_VALID_GROUP1 : constant Bit_Mask_Type := (Shift_Left(1, 1)) ;--*< group 1 is valid / received
PX4IO_P_CONTROLS_GROUP_VALID_GROUP2 : constant Bit_Mask_Type := (Shift_Left(1, 2)) ;--*< group 2 is valid / received
PX4IO_P_CONTROLS_GROUP_VALID_GROUP3 : constant Bit_Mask_Type := (Shift_Left(1, 3)) ;--*< group 3 is valid / received

-- raw text load to the mixer parser - ignores offset
PX4IO_PAGE_MIXERLOAD : constant := 52;

-- R/C channel config
PX4IO_PAGE_RC_CONFIG : constant := 53		;--*< R/C input configuration
PX4IO_P_RC_CONFIG_MIN : constant := 0		;--*< lowest input value
PX4IO_P_RC_CONFIG_CENTER : constant := 1		;--*< center input value
PX4IO_P_RC_CONFIG_MAX : constant := 2		;--*< highest input value
PX4IO_P_RC_CONFIG_DEADZONE : constant := 3		;--*< band around center that is ignored
PX4IO_P_RC_CONFIG_ASSIGNMENT : constant := 4		;--*< mapped input value
PX4IO_P_RC_CONFIG_ASSIGNMENT_MODESWITCH : constant := 100		;--*< magic value for mode switch
PX4IO_P_RC_CONFIG_OPTIONS : constant := 5		;--*< channel options bitmask
PX4IO_P_RC_CONFIG_OPTIONS_ENABLED : constant Bit_Mask_Type := (Shift_Left(1, 0));
PX4IO_P_RC_CONFIG_OPTIONS_REVERSE : constant Bit_Mask_Type := (Shift_Left(1, 1));
PX4IO_P_RC_CONFIG_STRIDE : constant := 6		;--*< spacing between channel config data

-- PWM output - overrides mixer
PX4IO_PAGE_DIRECT_PWM : constant := 54		;--*< 0..CONFIG_ACTUATOR_COUNT-1

-- PWM failsafe values - zero disables the output
PX4IO_PAGE_FAILSAFE_PWM : constant := 55		;--*< 0..CONFIG_ACTUATOR_COUNT-1

-- PWM failsafe values - zero disables the output
PX4IO_PAGE_SENSORS : constant := 56		;--*< Sensors connected to PX4IO
PX4IO_P_SENSORS_ALTITUDE : constant := 0		;--*< Altitude of an external sensor (HoTT or S.BUS2)

-- Debug and test page - not used in normal operation
PX4IO_PAGE_TEST : constant := 127;
PX4IO_P_TEST_LED : constant := 0		;--*< set the amber LED on/off

-- PWM minimum values for certain ESCs
PX4IO_PAGE_CONTROL_MIN_PWM : constant := 106		;--*< 0..CONFIG_ACTUATOR_COUNT-1

-- PWM maximum values for certain ESCs
PX4IO_PAGE_CONTROL_MAX_PWM : constant := 107		;--*< 0..CONFIG_ACTUATOR_COUNT-1

-- PWM disarmed values that are active, even when SAFETY_SAFE
PX4IO_PAGE_DISARMED_PWM : constant := 108			;-- 0..CONFIG_ACTUATOR_COUNT-1

--*
-- As-needed mixer data upload.
--
-- This message adds text to the mixer text buffer; the text
-- buffer is drained as the definitions are consumed.
--
F2I_MIXER_MAGIC : constant := 16#6d74#;
F2I_MIXER_ACTION_RESET : constant := 0;
F2I_MIXER_ACTION_APPEND : constant := 1;


type px4io_mixdata is
record
	f2i_mixer_magic : Unsigned_16;
	action : Unsigned_8;
	text : String(1 .. 10);	-- actual text size may vary
end record;

--*
-- Serial protocol encapsulation.
--

PKT_MAX_REGS : constant := 32 ;-- by agreement w/FMU

type Register_Array is array (1 .. PKT_MAX_REGS) of Unsigned_16;

type IOPacket_Type is
record
	count_code : Unsigned_8;
	crc : Unsigned_8;
	page : Unsigned_8;
	offset : Unsigned_8;
	regs : Register_Array;
end record;


PKT_CODE_READ : constant := 16#00#	;-- FMU->IO read transaction
PKT_CODE_WRITE : constant := 16#40#	;-- FMU->IO write transaction
PKT_CODE_SUCCESS : constant := 16#00#	;-- IO->FMU success reply
PKT_CODE_CORRUPT : constant := 16#40#	;-- IO->FMU bad packet reply
PKT_CODE_ERROR : constant := 16#80#	;-- IO->FMU register op error reply

PKT_CODE_MASK : constant := 16#c0#;
PKT_COUNT_MASK : constant := 16#3f#;

--  function Package_Count(pkt : IOPacket) return Unsigned_8 is
--  (pkt.count_code and PKT_COUNT_MASK);
--
--  function Package_Code(pkt : IOPacket) return Unsigned_8 is
--  (pkt.count_code and PKT_CODE_MASK);
--
--  function Package_Size(pkt : IOPacket) return Unsigned_8 is
--  ( (pkt.count_code and PKT_COUNT_MASK) + 4);  -- ToDo: check this




crc8_tab : array (1 .. 256) of Unsigned_8 := (
	16#00#, 16#07#, 16#0E#, 16#09#, 16#1C#, 16#1B#, 16#12#, 16#15#,
	16#38#, 16#3F#, 16#36#, 16#31#, 16#24#, 16#23#, 16#2A#, 16#2D#,
	16#70#, 16#77#, 16#7E#, 16#79#, 16#6C#, 16#6B#, 16#62#, 16#65#,
	16#48#, 16#4F#, 16#46#, 16#41#, 16#54#, 16#53#, 16#5A#, 16#5D#,
	16#E0#, 16#E7#, 16#EE#, 16#E9#, 16#FC#, 16#FB#, 16#F2#, 16#F5#,
	16#D8#, 16#DF#, 16#D6#, 16#D1#, 16#C4#, 16#C3#, 16#CA#, 16#CD#,
	16#90#, 16#97#, 16#9E#, 16#99#, 16#8C#, 16#8B#, 16#82#, 16#85#,
	16#A8#, 16#AF#, 16#A6#, 16#A1#, 16#B4#, 16#B3#, 16#BA#, 16#BD#,
	16#C7#, 16#C0#, 16#C9#, 16#CE#, 16#DB#, 16#DC#, 16#D5#, 16#D2#,
	16#FF#, 16#F8#, 16#F1#, 16#F6#, 16#E3#, 16#E4#, 16#ED#, 16#EA#,
	16#B7#, 16#B0#, 16#B9#, 16#BE#, 16#AB#, 16#AC#, 16#A5#, 16#A2#,
	16#8F#, 16#88#, 16#81#, 16#86#, 16#93#, 16#94#, 16#9D#, 16#9A#,
	16#27#, 16#20#, 16#29#, 16#2E#, 16#3B#, 16#3C#, 16#35#, 16#32#,
	16#1F#, 16#18#, 16#11#, 16#16#, 16#03#, 16#04#, 16#0D#, 16#0A#,
	16#57#, 16#50#, 16#59#, 16#5E#, 16#4B#, 16#4C#, 16#45#, 16#42#,
	16#6F#, 16#68#, 16#61#, 16#66#, 16#73#, 16#74#, 16#7D#, 16#7A#,
	16#89#, 16#8E#, 16#87#, 16#80#, 16#95#, 16#92#, 16#9B#, 16#9C#,
	16#B1#, 16#B6#, 16#BF#, 16#B8#, 16#AD#, 16#AA#, 16#A3#, 16#A4#,
	16#F9#, 16#FE#, 16#F7#, 16#F0#, 16#E5#, 16#E2#, 16#EB#, 16#EC#,
	16#C1#, 16#C6#, 16#CF#, 16#C8#, 16#DD#, 16#DA#, 16#D3#, 16#D4#,
	16#69#, 16#6E#, 16#67#, 16#60#, 16#75#, 16#72#, 16#7B#, 16#7C#,
	16#51#, 16#56#, 16#5F#, 16#58#, 16#4D#, 16#4A#, 16#43#, 16#44#,
	16#19#, 16#1E#, 16#17#, 16#10#, 16#05#, 16#02#, 16#0B#, 16#0C#,
	16#21#, 16#26#, 16#2F#, 16#28#, 16#3D#, 16#3A#, 16#33#, 16#34#,
	16#4E#, 16#49#, 16#40#, 16#47#, 16#52#, 16#55#, 16#5C#, 16#5B#,
	16#76#, 16#71#, 16#78#, 16#7F#, 16#6A#, 16#6D#, 16#64#, 16#63#,
	16#3E#, 16#39#, 16#30#, 16#37#, 16#22#, 16#25#, 16#2C#, 16#2B#,
	16#06#, 16#01#, 16#08#, 16#0F#, 16#1A#, 16#1D#, 16#14#, 16#13#,
	16#AE#, 16#A9#, 16#A0#, 16#A7#, 16#B2#, 16#B5#, 16#BC#, 16#BB#,
	16#96#, 16#91#, 16#98#, 16#9F#, 16#8A#, 16#8D#, 16#84#, 16#83#,
	16#DE#, 16#D9#, 16#D0#, 16#D7#, 16#C2#, 16#C5#, 16#CC#, 16#CB#,
	16#E6#, 16#E1#, 16#E8#, 16#EF#, 16#FA#, 16#FD#, 16#F4#, 16#F3#
);

-- function crcpacket(struct IOPacket *pkt) return static Unsigned_8;

--  function crcpacket(pkt : IOPacket_Type) return Unsigned_8 is
--  	c : Unsigned_8 := 0;
--  begin
--  	end : Unsigned_8 := PKT_COUNT(pkt);
--  	p   : Unsigned_8 := 0;
--
--  	while p < end loop
--  		c := crc8_tab(c xor * (p := p + 1));    -- loop over all bytes
--  	end loop;
--
--  	return c;
--  end crcpacket;

end PX4IO.Protocol;
