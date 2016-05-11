-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      LSM303D Driver
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Register definitions for the LSM303D
-- 
-- ToDo:
-- [ ] Implementation


package LSM303D is

ADDR_WHO_AM_I : constant :=			0x0F
WHO_I_AM : constant :=		0x49

ADDR_OUT_TEMP_L	: constant := 0x05;
ADDR_OUT_TEMP_H	: constant := 0x06;
ADDR_STATUS_M	: constant := 0x07;
ADDR_OUT_X_L_M  : constant := 0x08;
ADDR_OUT_X_H_M  : constant := 0x09;
ADDR_OUT_Y_L_M  : constant := 0x0A;
ADDR_OUT_Y_H_M	: constant := 0x0B;
ADDR_OUT_Z_L_M	: constant := 0x0C;
ADDR_OUT_Z_H_M	: constant := 0x0D;

ADDR_INT_CTRL_M		: constant := 0x12;
ADDR_INT_SRC_M		: constant := 0x13;
ADDR_REFERENCE_X	: constant := 0x1c;
ADDR_REFERENCE_Y	: constant := 0x1d;
ADDR_REFERENCE_Z	: constant := 0x1e;

ADDR_STATUS_A  : constant := 0x27;
ADDR_OUT_X_L_A : constant := 0x28;
ADDR_OUT_X_H_A : constant := 0x29;
ADDR_OUT_Y_L_A : constant := 0x2A;
ADDR_OUT_Y_H_A : constant := 0x2B;
ADDR_OUT_Z_L_A : constant := 0x2C;
ADDR_OUT_Z_H_A : constant := 0x2D;

ADDR_CTRL_REG0  : constant := 0x1F;
ADDR_CTRL_REG1  : constant := 0x20;
ADDR_CTRL_REG2  : constant := 0x21;
ADDR_CTRL_REG3  : constant := 0x22;
ADDR_CTRL_REG4  : constant := 0x23;
ADDR_CTRL_REG5  : constant := 0x24;
ADDR_CTRL_REG6  : constant := 0x25;
ADDR_CTRL_REG7	: constant := 0x26;

ADDR_FIFO_CTRL	: constant := 0x2e;
ADDR_FIFO_SRC	: constant := 0x2f;

ADDR_IG_CFG1		: constant := 0x30;
ADDR_IG_SRC1		: constant := 0x31;
ADDR_IG_THS1		: constant := 0x32;
ADDR_IG_DUR1		: constant := 0x33;
ADDR_IG_CFG2		: constant := 0x34;
ADDR_IG_SRC2		: constant := 0x35;
ADDR_IG_THS2		: constant := 0x36;
ADDR_IG_DUR2		: constant := 0x37;
ADDR_CLICK_CFG		: constant := 0x38;
ADDR_CLICK_SRC		: constant := 0x39;
ADDR_CLICK_THS		: constant := 0x3a;
ADDR_TIME_LIMIT		: constant := 0x3b;
ADDR_TIME_LATENCY	: constant := 0x3c;
ADDR_TIME_WINDOW	: constant := 0x3d;
ADDR_ACT_THS		: constant := 0x3e;
ADDR_ACT_DUR		: constant := 0x3f;




end LSM303D;