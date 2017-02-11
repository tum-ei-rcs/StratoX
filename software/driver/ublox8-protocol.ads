-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: U-Blox protocol definition. Following u-blox 6/7/8 Receiver Description


-- @author Thomas Gubler <thomasgubler@student.ethz.ch>
-- @author Julian Oes <julian@oes.ch>
-- @author Anton Babushkin <anton.babushkin@me.com>
--
-- @author Hannes Delago
--   (rework, add ubx7+ compatibility)
--
-- @author Emanuel Regnath (Ada Port)


-- Protocoll: https://de.wikipedia.org/wiki/NMEA_0183



with HIL; use HIL;

package ublox8.Protocol with SPARK_Mode is





   UBX_SYNC1 : constant := 16#B5#;
   UBX_SYNC2 : constant := 16#62#;

   -- Message Classes 
   UBX_CLASS_NAV : constant := 16#01#;
   UBX_CLASS_ACK : constant := 16#05#;
   UBX_CLASS_CFG : constant := 16#06#;
   UBX_CLASS_MON : constant := 16#0A#;
   UBX_CLASS_RTCM3 : constant := 16#F5# ;--*< This is undocumented (?) 

   -- Message IDs 
   UBX_ID_NAV_POSLLH : constant := 16#02#;
   UBX_ID_NAV_STATUS : constant := 16#03#;
   UBX_ID_NAV_DOP : constant := 16#04#;
   UBX_ID_NAV_SOL : constant := 16#06#;
   UBX_ID_NAV_PVT : constant := 16#07#;
   UBX_ID_NAV_VELNED : constant := 16#12#;
   UBX_ID_NAV_TIMEUTC : constant := 16#21#;
   UBX_ID_NAV_SVINFO : constant := 16#30#;
   UBX_ID_NAV_SAT : constant := 16#35#;
   UBX_ID_NAV_SVIN : constant := 16#3B#;
   UBX_ID_NAV_RELPOSNED : constant := 16#3C#;
   UBX_ID_ACK_NAK : constant := 16#00#;
   UBX_ID_ACK_ACK : constant := 16#01#;
   UBX_ID_CFG_PRT : constant := 16#00#;
   UBX_ID_CFG_MSG : constant := 16#01#;
   UBX_ID_CFG_RATE : constant := 16#08#;
   UBX_ID_CFG_NAV5 : constant := 16#24#;
   UBX_ID_CFG_SBAS : constant := 16#16#;
   UBX_ID_CFG_TMODE3 : constant := 16#71#;
   UBX_ID_MON_VER : constant := 16#04#;
   UBX_ID_MON_HW : constant := 16#09#;
   UBX_ID_RTCM31_005 : constant := 16#05#;
   UBX_ID_RTCM31_077 : constant := 16#4D#;
   UBX_ID_RTCM31_087 : constant := 16#57#;


   -- lengths
   UBX_LENGTH_CFG_PRT : constant := 20;
   UBX_LENGTH_CFG_MSG : constant := 8;
   UBX_LENGTH_NAV_PVT : constant := 92;
   UBX_LENGTH_ACK_ACK : constant := 2;


   -- Message Classes and IDs 
   --  UBX_MSG_NAV_POSLLH : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_POSLLH, 8));
   --  UBX_MSG_NAV_SOL : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_SOL, 8));
   --  UBX_MSG_NAV_DOP : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_DOP, 8));
   --  UBX_MSG_NAV_PVT : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_PVT, 8));
   --  UBX_MSG_NAV_VELNED : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_VELNED, 8));
   --  UBX_MSG_NAV_TIMEUTC : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_TIMEUTC, 8));
   --  UBX_MSG_NAV_SVINFO : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_SVINFO, 8));
   --  UBX_MSG_NAV_SAT : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_SAT, 8));
   --  UBX_MSG_NAV_SVIN : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_SVIN, 8));
   --  UBX_MSG_NAV_RELPOSNED : constant := ((UBX_CLASS_NAV) or Shift_Left(UBX_ID_NAV_RELPOSNED, 8));
   --  UBX_MSG_ACK_NAK : constant := ((UBX_CLASS_ACK) or Shift_Left(UBX_ID_ACK_NAK, 8));
   --  UBX_MSG_ACK_ACK : constant := ((UBX_CLASS_ACK) or Shift_Left(UBX_ID_ACK_ACK, 8));
   --  UBX_MSG_CFG_PRT : constant := ((UBX_CLASS_CFG) or Shift_Left(UBX_ID_CFG_PRT, 8));
   --  UBX_MSG_CFG_MSG : constant := ((UBX_CLASS_CFG) or Shift_Left(UBX_ID_CFG_MSG, 8));
   --  UBX_MSG_CFG_RATE : constant := ((UBX_CLASS_CFG) or Shift_Left(UBX_ID_CFG_RATE, 8));
   --  UBX_MSG_CFG_NAV5 : constant := ((UBX_CLASS_CFG) or Shift_Left(UBX_ID_CFG_NAV5, 8));
   --  UBX_MSG_CFG_SBAS : constant := ((UBX_CLASS_CFG) or Shift_Left(UBX_ID_CFG_SBAS, 8));
   --  UBX_MSG_CFG_TMODE3 : constant := ((UBX_CLASS_CFG) or Shift_Left(UBX_ID_CFG_TMODE3, 8));
   --  UBX_MSG_MON_HW : constant := ((UBX_CLASS_MON) or Shift_Left(UBX_ID_MON_HW, 8));
   --  UBX_MSG_MON_VER : constant := ((UBX_CLASS_MON) or Shift_Left(UBX_ID_MON_VER, 8));
   --  UBX_MSG_RTCM31_005 : constant := ((UBX_CLASS_RTCM3) or Shift_Left(UBX_ID_RTCM31_005, 8));
   --  UBX_MSG_RTCM31_077 : constant := ((UBX_CLASS_RTCM3) or Shift_Left(UBX_ID_RTCM31_077, 8));
   --  UBX_MSG_RTCM31_087 : constant := ((UBX_CLASS_RTCM3) or Shift_Left(UBX_ID_RTCM31_087, 8));

   -- RX NAV-PVT message content details 
   --   Bitfield "valid" masks 
   UBX_RX_NAV_PVT_VALIDVALIDDATE : constant := 16#01#	;--*< validDate (Valid UTC Date) 
   UBX_RX_NAV_PVT_VALIDVALIDTIME : constant := 16#02#	;--*< validTime (Valid UTC Time) 
   UBX_RX_NAV_PVT_VALIDFULLYRESOLVED : constant := 16#04#	;--*< fullyResolved (1 := UTC Time of Day has been fully resolved (no seconds uncertainty)) 

   --   Bitfield "flags" masks 
   UBX_RX_NAV_PVT_FLAGSGNSSFIXOK : constant := 16#01#	;--*< gnssFixOK (A valid fix (i.e within DOP and accuracy masks)) 
   UBX_RX_NAV_PVT_FLAGSDIFFSOLN : constant := 16#02#	;--*< diffSoln (1 if differential corrections were applied) 
   UBX_RX_NAV_PVT_FLAGSPSMSTATE : constant := 16#1C#	;--*< psmState (Power Save Mode state (see Power Management)) 
   UBX_RX_NAV_PVT_FLAGSHEADVEHVALID : constant := 16#20#	;--*< headVehValid (Heading of vehicle is valid) 

   -- RX NAV-TIMEUTC message content details 
   --   Bitfield "valid" masks 
   UBX_RX_NAV_TIMEUTC_VALIDVALIDTOW : constant := 16#01#	;--*< validTOW (1 := Valid Time of Week) 
   UBX_RX_NAV_TIMEUTC_VALIDVALIDKWN : constant := 16#02#	;--*< validWKN (1 := Valid Week Number) 
   UBX_RX_NAV_TIMEUTC_VALIDVALIDUTC : constant := 16#04#	;--*< validUTC (1 := Valid UTC Time) 
   UBX_RX_NAV_TIMEUTC_VALIDUTCSTANDARD : constant := 16#F0#	;--*< utcStandard (0..15 := UTC standard identifier) 

   -- TX CFG-PRT message contents 
   UBX_TX_CFG_PRT_PORTID : constant := 16#01#		;--*< UART1 
   UBX_TX_CFG_PRT_PORTID_USB : constant := 16#03#		;--*< USB 
   UBX_TX_CFG_PRT_MODE : constant := 16#0000_008D0#	;--*< 2#0000100011010000#: 8N1 
   UBX_TX_CFG_PRT_BAUDRATE : constant :=38_400		;--*< choose38_400 as GPS baudrate 
   --UBX_TX_CFG_PRT_INPROTOMASK : constant := (2**5) or (2**2) or 16#01#	;--*< RTCM3 in and RTCM2 in and UBX in 
   UBX_TX_CFG_PRT_OUTPROTOMASK_GPS : constant := (16#01#)			;--*< UBX out 
   --UBX_TX_CFG_PRT_OUTPROTOMASK_RTCM : constant := (2**5) or 16#01#		;--*< RTCM3 out and UBX out 

   -- TX CFG-RATE message contents 
   UBX_TX_CFG_RATE_MEASINTERVAL : constant := 200		;--*< 200ms for 5Hz 
   UBX_TX_CFG_RATE_NAVRATE : constant := 1		;--*< cannot be changed 
   UBX_TX_CFG_RATE_TIMEREF : constant := 0		;--*< 0: UTC, 1: GPS time 

   -- TX CFG-NAV5 message contents 
   UBX_TX_CFG_NAV5_MASK : constant := 00_005		;--*< Only update dynamic model and fix mode 
   UBX_TX_CFG_NAV5_DYNMODEL : constant := 7;  --*< 0 Portable, 2 Stationary, 3 Pedestrian, 4 Automotive, 5 Sea, 6 Airborne <1g, 7 Airborne <2g, 8 Airborne <4g 
   UBX_TX_CFG_NAV5_DYNMODEL_RTCM : constant := 2;
   UBX_TX_CFG_NAV5_FIXMODE : constant := 2		;--*< 1 2D only, 2 3D only, 3 Auto 2D/3D 

   -- TX CFG-SBAS message contents 
   UBX_TX_CFG_SBAS_MODE_ENABLED : constant := 1				;--*< SBAS enabled 
   UBX_TX_CFG_SBAS_MODE_DISABLED : constant := 0				;--*< SBAS disabled 
   UBX_TX_CFG_SBAS_MODE : constant := UBX_TX_CFG_SBAS_MODE_DISABLED	;--*< SBAS enabled or disabled 

   -- TX CFG-MSG message contents 
   UBX_TX_CFG_MSG_RATE1_5HZ : constant := 16#01# 		;--*< {16#00#, 16#01#, 16#00#, 16#00#, 16#00#, 16#00#} the second entry is for UART1 
   UBX_TX_CFG_MSG_RATE1_1HZ : constant := 16#05#		;--*< {16#00#, 16#05#, 16#00#, 16#00#, 16#00#, 16#00#} the second entry is for UART1 
   UBX_TX_CFG_MSG_RATE1_05HZ : constant := 10;

   -- TX CFG-TMODE3 message contents 
   UBX_TX_CFG_TMODE3_FLAGS : constant := 1 	    	;--*< start survey-in 
   UBX_TX_CFG_TMODE3_SVINMINDUR : constant := (2*60)		;--*< survey-in: minimum duration [s] (higher:=higher precision) 
   UBX_TX_CFG_TMODE3_SVINACCLIMIT : constant := 10_000	;--*< survey-in: position accuracy limit 0.1[mm] 

   -- RTCM3 
   RTCM3_PREAMBLE : constant := 16#D3#;
   RTCM_BUFFER_LENGTH : constant := 110		;--*< maximum message length of an RTCM message 







   subtype Header_Index_Type is Natural range 1 .. 6;
   HEADER_SYNC_CHAR_1 : Header_Index_Type := 1;
   HEADER_SYNC_CHAR_2 : Header_Index_Type := 2;
   HEADER_MSG_CLASS : Header_Index_Type := 3;
   HEADER_MSG_ID : Header_Index_Type := 4;
   HEADER_LENGTH : Header_Index_Type := 5;

   subtype UBX_Header_Array is Byte_Array(Header_Index_Type);

   subtype Checksum_Index_Type is Natural range 1 .. 2;
   CK_A : constant Checksum_Index_Type := 1;
   CK_B : constant Checksum_Index_Type := 2;

   subtype UBX_Checksum_Array is Byte_Array(Checksum_Index_Type);


   --  type rtcm_message_t is
   --  record
   --  	Unsigned_8			buffer(RTCM_BUFFER_LENGTH);
   --  	pos : Unsigned_16;						--/< next position in buffer
   --  	message_length : Unsigned_16;					--/< message length without header and CRC (both 3 bytes)
   --  end record;
   --
   --  -- General: Header 
   --  type ubx_header_t is record
   --  	sync1 : Unsigned_8;
   --  	sync2 : Unsigned_8;
   --  	msg : Unsigned_16;
   --  	length : Unsigned_16;
   --  end record;
   --  
   --  
   --  
   --  
   --  -- General: Checksum 
   --  type ubx_checksum_t is record
   --  	ck_a : Unsigned_8;
   --  	ck_b : Unsigned_8;
   --  end record;
   --  
   --  -- Rx NAV-POSLLH 
   --  type ubx_payload_rx_nav_posllh_t is record
   --  	iTOW : Unsigned_32;		--*< GPS Time of Week [ms] 
   --  	lon : Integer_32;		--*< Longitude [1e-7 deg] 
   --  	lat : Integer_32;		--*< Latitude [1e-7 deg] 
   --  	height : Integer_32;		--*< Height above ellipsoid [mm] 
   --  	hMSL : Integer_32;		--*< Height above mean sea level [mm] 
   --  	hAcc : Unsigned_32;  		--*< Horizontal accuracy estimate [mm] 
   --  	vAcc : Unsigned_32;  		--*< Vertical accuracy estimate [mm] 
   --  end record;
   --  
   --  -- Rx NAV-DOP 
   --  type ubx_payload_rx_nav_dop_t is record
   --  	iTOW : Unsigned_32;		--*< GPS Time of Week [ms] 
   --  	gDOP : Unsigned_16;		--*< Geometric DOP [0.01] 
   --  	pDOP : Unsigned_16;		--*< Position DOP [0.01] 
   --  	tDOP : Unsigned_16;		--*< Time DOP [0.01] 
   --  	vDOP : Unsigned_16;		--*< Vertical DOP [0.01] 
   --  	hDOP : Unsigned_16;		--*< Horizontal DOP [0.01] 
   --  	nDOP : Unsigned_16;		--*< Northing DOP [0.01] 
   --  	eDOP : Unsigned_16;		--*< Easting DOP [0.01] 
   --  end record;
   --  
   --  -- Rx NAV-SOL 
   --  type ubx_payload_rx_nav_sol_t is record
   --  	iTOW : Unsigned_32;		--*< GPS Time of Week [ms] 
   --  	fTOW : Integer_32;		--*< Fractional part of iTOW (range: +/500_000) [ns] 
   --  	week : Integer_16;		--*< GPS week 
   --  	gpsFix : Unsigned_8;		--*< GPSfix type: 0 := No fix, 1 := Dead Reckoning only, 2 := 2D fix, 3 := 3d-fix, 4 := GPS + dead reckoning, 5 := time only fix 
   --  	flags : Unsigned_8;
   --  	ecefX : Integer_32;
   --  	ecefY : Integer_32;
   --  	ecefZ : Integer_32;
   --  	pAcc : Unsigned_32;
   --  	ecefVX : Integer_32;
   --  	ecefVY : Integer_32;
   --  	ecefVZ : Integer_32;
   --  	sAcc : Unsigned_32;
   --  	pDOP : Unsigned_16;		--*< Position DOP [0.01] 
   --  	reserved1 : Unsigned_8;
   --  	numSV : Unsigned_8;		--*< Number of SVs used in Nav Solution 
   --  	reserved2 : Unsigned_32;
   --  end record;
   --  
   --  -- Rx NAV-PVT (ubx8) 
   --  type ubx_payload_rx_nav_pvt_t is record
   --  	iTOW : Unsigned_32;		--*< GPS Time of Week [ms] 
   --  	year : Unsigned_16; 		--*< Year (UTC)
   --  	month : Unsigned_8; 		--*< Month, range 1..12 (UTC) 
   --  	day : Unsigned_8; 		--*< Day of month, range 1..31 (UTC) 
   --  	hour : Unsigned_8; 		--*< Hour of day, range 0..23 (UTC) 
   --  	min : Unsigned_8; 		--*< Minute of hour, range 0..59 (UTC) 
   --  	sec : Unsigned_8;		--*< Seconds of minute, range 0..60 (UTC) 
   --  	valid : Unsigned_8; 		--*< Validity flags (see UBX_RX_NAV_PVT_VALID...) 
   --  	tAcc : Unsigned_32; 		--*< Time accuracy estimate (UTC) [ns] 
   --  	nano : Integer_32;		--*< Fraction of second (UTC) [-1e9...1e9 ns] 
   --  	fixType : Unsigned_8;	--*< GNSSfix type: 0 := No fix, 1 := Dead Reckoning only, 2 := 2D fix, 3 := 3d-fix, 4 := GNSS + dead reckoning, 5 := time only fix 
   --  	flags : Unsigned_8;		--*< Fix Status Flags (see UBX_RX_NAV_PVT_FLAGS...) 
   --  	reserved1 : Unsigned_8;
   --  	numSV : Unsigned_8;		--*< Number of SVs used in Nav Solution 
   --  	lon : Integer_32;		--*< Longitude [1e-7 deg] 
   --  	lat : Integer_32;		--*< Latitude [1e-7 deg] 
   --  	height : Integer_32;		--*< Height above ellipsoid [mm] 
   --  	hMSL : Integer_32;		--*< Height above mean sea level [mm] 
   --  	hAcc : Unsigned_32;  		--*< Horizontal accuracy estimate [mm] 
   --  	vAcc : Unsigned_32;  		--*< Vertical accuracy estimate [mm] 
   --  	velN : Integer_32;		--*< NED north velocity [mm/s]
   --  	velE : Integer_32;		--*< NED east velocity [mm/s]
   --  	velD : Integer_32;		--*< NED down velocity [mm/s]
   --  	gSpeed : Integer_32;		--*< Ground Speed (2-D) [mm/s] 
   --  	headMot : Integer_32;	--*< Heading of motion (2-D) [1e-5 deg] 
   --  	sAcc : Unsigned_32;		--*< Speed accuracy estimate [mm/s] 
   --  	headAcc : Unsigned_32;	--*< Heading accuracy estimate (motion and vehicle) [1e-5 deg] 
   --  	pDOP : Unsigned_16;		--*< Position DOP [0.01] 
   --  	reserved2 : Unsigned_16;
   --  	reserved3 : Unsigned_32;
   --  	headVeh : Integer_32;	--*< (ubx8+ only) Heading of vehicle (2-D) [1e-5 deg] 
   --  	reserved4 : Unsigned_32;	--*< (ubx8+ only) 
   --  end record;
   --  UBX_PAYLOAD_RX_NAV_PVT_SIZE_UBX7 : constant := (sizeof(ubx_payload_rx_nav_pvt_t) - 8);
   --  UBX_PAYLOAD_RX_NAV_PVT_SIZE_UBX8 : constant := (sizeof(ubx_payload_rx_nav_pvt_t));
   --  
   --  -- Rx NAV-TIMEUTC 
   --  type ubx_payload_rx_nav_timeutc_t is record
   --  	iTOW : Unsigned_32;		--*< GPS Time of Week [ms] 
   --  	tAcc : Unsigned_32; 		--*< Time accuracy estimate (UTC) [ns] 
   --  	nano : Integer_32;		--*< Fraction of second, range -1e9 .. 1e9 (UTC) [ns] 
   --  	year : Unsigned_16; 		--*< Year, range1_999..2099 (UTC) 
   --  	month : Unsigned_8; 		--*< Month, range 1..12 (UTC) 
   --  	day : Unsigned_8; 		--*< Day of month, range 1..31 (UTC) 
   --  	hour : Unsigned_8; 		--*< Hour of day, range 0..23 (UTC) 
   --  	min : Unsigned_8; 		--*< Minute of hour, range 0..59 (UTC) 
   --  	sec : Unsigned_8;		--*< Seconds of minute, range 0..60 (UTC) 
   --  	valid : Unsigned_8; 		--*< Validity Flags (see UBX_RX_NAV_TIMEUTC_VALID...) 
   --  end record;
   --  
   --  -- Rx NAV-SVINFO Part 1 
   --  type ubx_payload_rx_nav_svinfo_part1_t is record
   --  	iTOW : Unsigned_32;		--*< GPS Time of Week [ms] 
   --  	numCh : Unsigned_8; 		--*< Number of channels 
   --  	globalFlags : Unsigned_8;
   --  	reserved2 : Unsigned_16;
   --  end record;
   --  
   --  -- Rx NAV-SVINFO Part 2 (repeated) 
   --  type ubx_payload_rx_nav_svinfo_part2_t is record
   --  	chn : Unsigned_8; 		--*< Channel number, 255 for SVs not assigned to a channel 
   --  	svid : Unsigned_8; 		--*< Satellite ID 
   --  	flags : Unsigned_8;
   --  	quality : Unsigned_8;
   --  	Unsigned_8		cno;		--*< Carrier to Noise Ratio (Strength : Signal) [dbHz] 
   --  	elev : Integer_8; 		--*< Elevation [deg] 
   --  	azim : Integer_16; 		--*< Azimuth [deg] 
   --  	prRes : Integer_32; 		--*< Pseudo range residual [cm] 
   --  end record;
   --  
   --  -- Rx NAV-SVIN (survey-in info) 
   --  type ubx_payload_rx_nav_svin_t is record
   --  	version : Unsigned_8;
   --  	Unsigned_8     reserved1(3);
   --  	iTOW : Unsigned_32;
   --  	dur : Unsigned_32;
   --  	meanX : Integer_32;
   --  	meanY : Integer_32;
   --  	meanZ : Integer_32;
   --  	meanXHP : Integer_8;
   --  	meanYHP : Integer_8;
   --  	meanZHP : Integer_8;
   --  	reserved2 : Integer_8;
   --  	meanAcc : Unsigned_32;
   --  	obs : Unsigned_32;
   --  	valid : Unsigned_8;
   --  	active : Unsigned_8;
   --  	Unsigned_8     reserved3(2);
   --  end record;
   --  
   --  -- Rx NAV-VELNED 
   --  type ubx_payload_rx_nav_velned_t is record
   --  	iTOW : Unsigned_32;		--*< GPS Time of Week [ms] 
   --  	velN : Integer_32;		--*< North velocity component [cm/s]
   --  	velE : Integer_32;		--*< East velocity component [cm/s]
   --  	velD : Integer_32;		--*< Down velocity component [cm/s]
   --  	speed : Unsigned_32;		--*< Speed (3-D) [cm/s] 
   --  	gSpeed : Unsigned_32;		--*< Ground speed (2-D) [cm/s] 
   --  	heading : Integer_32;	--*< Heading of motion 2-D [1e-5 deg] 
   --  	sAcc : Unsigned_32;		--*< Speed accuracy estimate [cm/s] 
   --  	cAcc : Unsigned_32;		--*< Course / Heading accuracy estimate [1e-5 deg] 
   --  end record;
   --  
   --  -- Rx MON-HW (ubx6) 
   --  type ubx_payload_rx_mon_hw_ubx6_t is record
   --  	pinSel : Unsigned_32;
   --  	pinBank : Unsigned_32;
   --  	pinDir : Unsigned_32;
   --  	pinVal : Unsigned_32;
   --  	noisePerMS : Unsigned_16;
   --  	agcCnt : Unsigned_16;
   --  	aStatus : Unsigned_8;
   --  	aPower : Unsigned_8;
   --  	flags : Unsigned_8;
   --  	reserved1 : Unsigned_8;
   --  	usedMask : Unsigned_32;
   --  	Unsigned_8		VP(25);
   --  	jamInd : Unsigned_8;
   --  	reserved3 : Unsigned_16;
   --  	pinIrq : Unsigned_32;
   --  	pullH : Unsigned_32;
   --  	pullL : Unsigned_32;
   --  end record;
   --  
   --  -- Rx MON-HW (ubx7+) 
   --  type ubx_payload_rx_mon_hw_ubx7_t is record
   --  	pinSel : Unsigned_32;
   --  	pinBank : Unsigned_32;
   --  	pinDir : Unsigned_32;
   --  	pinVal : Unsigned_32;
   --  	noisePerMS : Unsigned_16;
   --  	agcCnt : Unsigned_16;
   --  	aStatus : Unsigned_8;
   --  	aPower : Unsigned_8;
   --  	flags : Unsigned_8;
   --  	reserved1 : Unsigned_8;
   --  	usedMask : Unsigned_32;
   --  	Unsigned_8		VP(17);
   --  	jamInd : Unsigned_8;
   --  	reserved3 : Unsigned_16;
   --  	pinIrq : Unsigned_32;
   --  	pullH : Unsigned_32;
   --  	pullL : Unsigned_32;
   --  end record;
   --  
   --  -- Rx MON-VER Part 1 
   --  type ubx_payload_rx_mon_ver_part1_t is record
   --  	Unsigned_8		swVersion(30);
   --  	Unsigned_8		hwVersion(10);
   --  end record;
   --  
   --  -- Rx MON-VER Part 2 (repeated) 
   --  type ubx_payload_rx_mon_ver_part2_t is record
   --  	Unsigned_8		extension(30);
   --  end record;
   --  
   --  -- Rx ACK-ACK 
   --  typedef	union {
   --  	msg : Unsigned_16;
   --  	type is
   --  record
   --  		clsID : Unsigned_8;
   --  		msgID : Unsigned_8;
   --  	end record;
   --  } ubx_payload_rx_ack_ack_t;
   --  
   --  -- Rx ACK-NAK 
   --  typedef	union {
   --  	msg : Unsigned_16;
   --  	type is
   --  record
   --  		clsID : Unsigned_8;
   --  		msgID : Unsigned_8;
   --  	end record;
   --  } ubx_payload_rx_ack_nak_t;
   --  
   --  -- Tx CFG-PRT 
   --  type is
   --  record
   --  	portID : Unsigned_8;
   --  	reserved0 : Unsigned_8;
   --  	txReady : Unsigned_16;
   --  	mode : Unsigned_32;
   --  	baudRate : Unsigned_32;
   --  	inProtoMask : Unsigned_16;
   --  	outProtoMask : Unsigned_16;
   --  	flags : Unsigned_16;
   --  	reserved5 : Unsigned_16;
   --  end record ubx_payload_tx_cfg_prt_t;
   --  
   --  -- Tx CFG-RATE 
   --  type is
   --  record
   --  	measRate : Unsigned_16;	--*< Measurement Rate, GPS measurements are taken every measRate milliseconds 
   --  	navRate : Unsigned_16;	--*< Navigation Rate, in number of measurement cycles. This parameter cannot be changed, and must be set to 1 
   --  	timeRef : Unsigned_16;	--*< Alignment to reference time: 0 := UTC time, 1 := GPS time 
   --  end record ubx_payload_tx_cfg_rate_t;
   --  
   --  -- Tx CFG-NAV5 
   --  type is
   --  record
   --  	mask : Unsigned_16;
   --  	dynModel : Unsigned_8;	--*< Dynamic Platform model: 0 Portable, 2 Stationary, 3 Pedestrian, 4 Automotive, 5 Sea, 6 Airborne <1g, 7 Airborne <2g, 8 Airborne <4g 
   --  	fixMode : Unsigned_8;	--*< Position Fixing Mode: 1 2D only, 2 3D only, 3 Auto 2D/3D 
   --  	fixedAlt : Integer_32;
   --  	fixedAltVar : Unsigned_32;
   --  	minElev : Integer_8;
   --  	drLimit : Unsigned_8;
   --  	pDop : Unsigned_16;
   --  	tDop : Unsigned_16;
   --  	pAcc : Unsigned_16;
   --  	tAcc : Unsigned_16;
   --  	staticHoldThresh : Unsigned_8;
   --  	dgpsTimeOut : Unsigned_8;
   --  	cnoThreshNumSVs : Unsigned_8;	--*< (ubx7+ only,else0) 
   --  	cnoThresh : Unsigned_8;		--*< (ubx7+ only,else0) 
   --  	reserved : Unsigned_16;
   --  	staticHoldMaxDist : Unsigned_16;	--*< (ubx8+ only,else0) 
   --  	utcStandard : Unsigned_8;		--*< (ubx8+ only,else0) 
   --  	reserved3 : Unsigned_8;
   --  	reserved4 : Unsigned_32;
   --  end record ubx_payload_tx_cfg_nav5_t;
   --  
   --  -- tx cfg-sbas 
   --  type is
   --  record
   --  	mode : Unsigned_8;
   --  	usage : Unsigned_8;
   --  	maxSBAS : Unsigned_8;
   --  	scanmode2 : Unsigned_8;
   --  	scanmode1 : Unsigned_32;
   --  end record ubx_payload_tx_cfg_sbas_t;
   --  
   --  -- Tx CFG-MSG 
   --  struct {
   --  	union {
   --  		msg : Unsigned_16;
   --  		type is
   --  record
   --  			msgClass : Unsigned_8;
   --  			msgID : Unsigned_8;
   --  		end record;
   --  	};
   --  	rate : Unsigned_8;
   --  } ubx_payload_tx_cfg_msg_t;
   --  
   --  -- CFG-TMODE3 ublox 8 (protocol version >= 20) 
   --  type is
   --  record
   --  	version : Unsigned_8;
   --  	reserved1 : Unsigned_8;
   --  	flags : Unsigned_16;
   --  	ecefXOrLat : Integer_32;
   --  	ecefYOrLon : Integer_32;
   --  	ecefZOrAlt : Integer_32;
   --  	ecefXOrLatHP : Integer_8;
   --  	ecefYOrLonHP : Integer_8;
   --  	ecefZOrAltHP : Integer_8;
   --  	reserved2 : Unsigned_8;
   --  	fixedPosAcc : Unsigned_32;
   --  	svinMinDur : Unsigned_32;
   --  	svinAccLimit : Unsigned_32;
   --  	Unsigned_8     reserved3(8);
   --  end record ubx_payload_tx_cfg_tmode3_t;
   --  
   --  -- General message and payload buffer union 
   --  union {
   --  	payload_rx_nav_pvt : ubx_payload_rx_nav_pvt_t;
   --  	payload_rx_nav_posllh : ubx_payload_rx_nav_posllh_t;
   --  	payload_rx_nav_sol : ubx_payload_rx_nav_sol_t;
   --  	payload_rx_nav_dop : ubx_payload_rx_nav_dop_t;
   --  	payload_rx_nav_timeutc : ubx_payload_rx_nav_timeutc_t;
   --  	payload_rx_nav_svinfo_part1 : ubx_payload_rx_nav_svinfo_part1_t;
   --  	payload_rx_nav_svinfo_part2 : ubx_payload_rx_nav_svinfo_part2_t;
   --  	payload_rx_nav_svin : ubx_payload_rx_nav_svin_t;
   --  	payload_rx_nav_velned : ubx_payload_rx_nav_velned_t;
   --  	payload_rx_mon_hw_ubx6 : ubx_payload_rx_mon_hw_ubx6_t;
   --  	payload_rx_mon_hw_ubx7 : ubx_payload_rx_mon_hw_ubx7_t;
   --  	payload_rx_mon_ver_part1 : ubx_payload_rx_mon_ver_part1_t;
   --  	payload_rx_mon_ver_part2 : ubx_payload_rx_mon_ver_part2_t;
   --  	payload_rx_ack_ack : ubx_payload_rx_ack_ack_t;
   --  	payload_rx_ack_nak : ubx_payload_rx_ack_nak_t;
   --  	payload_tx_cfg_prt : ubx_payload_tx_cfg_prt_t;
   --  	payload_tx_cfg_rate : ubx_payload_tx_cfg_rate_t;
   --  	payload_tx_cfg_nav5 : ubx_payload_tx_cfg_nav5_t;
   --  	payload_tx_cfg_sbas : ubx_payload_tx_cfg_sbas_t;
   --  	payload_tx_cfg_msg : ubx_payload_tx_cfg_msg_t;
   --  	payload_tx_cfg_tmode3 : ubx_payload_tx_cfg_tmode3_t;
   --  } ubxbuf_t;
   --  
   --  #pragma pack(pop)
   --  --** END OF u-blox protocol binary message and payload definitions **
   --  
   --  -- Decoder state 
   --  enum {
   --  	UBX_DECODE_SYNC1 := 0,
   --  	UBX_DECODE_SYNC2,
   --  	UBX_DECODE_CLASS,
   --  	UBX_DECODE_ID,
   --  	UBX_DECODE_LENGTH1,
   --  	UBX_DECODE_LENGTH2,
   --  	UBX_DECODE_PAYLOAD,
   --  	UBX_DECODE_CHKSUM1,
   --  	UBX_DECODE_CHKSUM2,
   --  
   --  	UBX_DECODE_RTCM3
   --  } ubxdecode_state_t;
   --  
   --  -- Rx message state 
   --  enum {
   --  	UBX_RXMSG_IGNORE := 0,
   --  	UBX_RXMSG_HANDLE,
   --  	UBX_RXMSG_DISABLE,
   --  	UBX_RXMSG_ERROR_LENGTH
   --  } ubx_rxmsg_state_t;
   --  
   --  -- ACK state 
   --  enum {
   --  	UBX_ACK_IDLE := 0,
   --  	UBX_ACK_WAITING,
   --  	UBX_ACK_GOT_ACK,
   --  	UBX_ACK_GOT_NAK
   --  } ubxack_state_t;
   --  
   --  
   --  class GPSDriverUBX : public GPSHelper
   --  {
   --  <<public>>
   --  	GPSDriverUBX(callback : GPSCallbackPtr, void *callback_user, struct vehiclegps_position_s *gps_position,
   --  		     struct satellite_info_s *satellite_info);
   --  	virtual not GPSDriverUBX;
   --  	function receive(timeout : unsigned) return Integer;
   --  	function configure(unsigned &baudrate; output_mode : OutputMode) return Integer;
   --  
   --  	function restartSurveyIn return Integer;
   --  <<private>>
   --  
   --  	--*
   --  	-- Parse the binary UBX packet
   --  	--
   --  	function parseChar(b : in Unsigned_8) return Integer;
   --  
   --  	--*
   --  	-- Start payload rx
   --  	--
   --  	function payloadRxInit return Integer;
   --  
   --  	--*
   --  	-- Add payload rx byte
   --  	--
   --  	function payloadRxAdd(b : in Unsigned_8) return Integer;
   --  	function payloadRxAddNavSvinfo(b : in Unsigned_8) return Integer;
   --  	function payloadRxAddMonVer(b : in Unsigned_8) return Integer;
   --  
   --  	--*
   --  	-- Finish payload rx
   --  	--
   --  	function payloadRxDone return Integer;
   --  
   --  	--*
   --  	-- Reset the parse state machine for a fresh start
   --  	--
   --  	procedure decodeInit;
   --  
   --  	--*
   --  	-- While parsing add every byte (except the sync bytes) to the checksum
   --  	--
   --  	procedure addByteToChecksum(const Unsigned_8);
   --  
   --  	--*
   --  	-- Send a message
   --  	-- @return true on success, false on write error (set : errno)
   --  	--
   --  	function sendMessage(msg : in Unsigned_16; const Unsigned_8 *payload; length : in Unsigned_16) return Boolean;
   --  
   --  	--*
   --  	-- Configure message rate
   --  	-- @return true on success, false on write error
   --  	--
   --  	function configureMessageRate(msg : in Unsigned_16; rate : in Unsigned_8) return Boolean;
   --  
   --  	--*
   --  	-- Calculate and add checksum for given buffer
   --  	--
   --  	procedure calcChecksum(const Unsigned_8 *buffer; length : in Unsigned_16; ubx_checksum_t *checksum);
   --  
   --  	--*
   --  	-- Wait for message acknowledge
   --  	--
   --  	function waitForAck(msg : in Unsigned_16; timeout : in unsigned; report : in Boolean) return Integer;
   --  
   --  	--*
   --  	-- combines the configure_message_rate and wait_for_ack calls
   --  	-- @return true on success
   --  	--
   --  	inline Boolean configureMessageRateAndAck(msg : Unsigned_16, rate : Unsigned_8, Boolean report_ack_error := false);
   --  
   --  	--*
   --  	-- Calculate FNV1 hash
   --  	--
   --  	function fnv1_32_str(Unsigned_8 *str; hval : Unsigned_32) return Unsigned_32;
   --  
   --  	struct vehiclegps_position_s *gps_position;
   --  	struct satellite_info_s *satellite_info;
   --  	configured : Boolean;
   --  	ack_state : ubxack_state_t;
   --  	got_posllh : Boolean;
   --  	got_velned : Boolean;
   --  	decode_state : ubxdecode_state_t;
   --  	rx_msg : Unsigned_16;
   --  	rx_state : ubx_rxmsg_state_t;
   --  	rx_payload_length : Unsigned_16;
   --  	rx_payload_index : Unsigned_16;
   --  	rx_ck_a : Unsigned_8;
   --  	rx_ck_b : Unsigned_8;
   --  	disable_cmd_last : gps_abstime;
   --  	ack_waiting_msg : Unsigned_16;
   --  	buf : ubxbuf_t;
   --  	ubx_version : Unsigned_32;
   --  	use_nav_pvt : Boolean;
   --  	output_mode : OutputMode := OutputMode::GPS;
   --  
   --  	rtcm_message_t	*rtcm_message := nullptr;
   --  };


end ublox8.Protocol;
