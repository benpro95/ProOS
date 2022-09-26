/*
 *  @(#)volcontrol.h	1.10 16/12/19
 *
 *  volcontrol.h: volume control constants
 *
 *  Volu-Master(tm)
 *  Arduino controller-based digital volume control and
 *  input/output selector
 *
 *  LCDuino-1/Volu-Master Team: Bryan Levin, Ti Kan
 *
 *  Project websites:
 *	http://www.amb.org/audio/lcduino-1/
 *	http://www.amb.org/audio/delta1/
 *	http://www.amb.org/audio/delta2/
 *  Discussion forum:
 *	http://www.amb.org/forum/
 *
 *  Author:
 *	Bryan Levin (Sercona Audio), Ti Kan (AMB Laboratories)
 *	Copyright (c) 2009-2016 Bryan Levin, Ti Kan
 *	All rights reserved.
 *
 *  LICENSE
 *  -------
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef _VOLCONTROL_H_
#define _VOLCONTROL_H_

// we have a global string buffer that we use over and over again
// for short-term use
#define STRING_BUF_MAXLEN	16+1

// how long to wait at the banner screen
#define SPLASHSCRNTIME		3000	// in milliseconds

// Maximum number of I/O ports
#define MAX_IOPORTS		8


/*********************************
 * EEPROM storage of ports-table
 *********************************/

/*
 * lengths of strings present in FLASH (_P) and EEPROM
 */

// our 8 input/output ports, user-settable
#define LEN_PORTNAME_STRING	8

// power-on and clock display user-settable banner lines
#define LEN_BANNER_STRING	16

// generic 8-byte string
#define NAME_ST8_MAXLEN		8


/*
 * LCD locations for various fields
 */

// top line of 16x2
#define LCD_MAIN_IN_PORTNAME_LOC	(LCD_CURS_POS_L1_HOME+0)
#define LCD_MAIN_OUT_PORTNAME_LOC	(LCD_CURS_POS_L1_HOME+8)

// bottom line of 16x2
#define LCD_MAIN_SLEEP_COUNTDOWN_LOC	(LCD_CURS_POS_L2_HOME+0)
#define LCD_MAIN_MUTE_LOC		(LCD_CURS_POS_L2_HOME+0)
#define LCD_MAIN_CLOCK_LOC		(LCD_CURS_POS_L2_HOME+0)


/*
 * IFC = internal function codes
 *
 * these are logical mappings of physical IR keypad keys to internal
 * callable functions.  its the way we soft-map keys on a remote to
 * things that happen when you press those keys.
 */

// 'alias' allows more than one IR source to trigger the same local function
//  use-case: 2 IR handheld remotes have volume-up.  you want both to trigger
//  the local volume-up-slow function when either is pressed.

// first come the most-used 5 keys (we cache them in RAM for speed)
#define IFC_INVALID_CODE	-1

#define IFC_VOL_UP_FAST		0	// up-arrow
#define IFC_VOL_DOWN_FAST	1	// down-arrow
#define IFC_VOL_UP_SLOW		2	// right-arrow
#define IFC_VOL_DOWN_SLOW	3	// left-arrow

// aliases.  same eeprom offset and value
#define IFC_UP_ARROW		0
#define IFC_DOWN_ARROW		1
#define IFC_RIGHT_ARROW		2
#define IFC_LEFT_ARROW		3

#define IFC_MUTE_ONOFF		4	// 'enter' button, center of 'arrows'

// the remaining codes are searched from EEPROM and are not cached in RAM

#define IFC_VOL_UP_ALIAS	5
#define IFC_VOL_DOWN_ALIAS	6

#define IFC_POWER_ONOFF		7
#define IFC_MENU		8
#define IFC_SLEEP_ONOFF		9	// toggle sleep on or off
#define IFC_BACKLIGHT		10	// backlight full, auto-dim, dark
#define IFC_DISPLAY_MODE	11	// bargraph, sleep, time, bigfonts

// the 8 I/O ports
#define IFC_KEYPAD1		12
#define IFC_KEYPAD2		13
#define IFC_KEYPAD3		14
#define IFC_KEYPAD4		15
#define IFC_KEYPAD5		16
#define IFC_KEYPAD6		17
#define IFC_KEYPAD7		18
#define IFC_KEYPAD8		19

// remaining 2 keypad numbers (not currently used)
#define IFC_KEYPAD9		20
#define IFC_KEYPAD0		21

#define IFC_MULTI_OUT		22	// out port style: TB or RB

// don't touch this, it has to be the last entry in this list
#define IFC_KEY_SENTINEL	23	// must always be the last in the list

#define MAX_FUNCTS		IFC_KEY_SENTINEL

// Special magic number in the EEPROM for Volu-Master
#define MY_MAGIC		0xf2	// 242

/*
 * eeprom locations (slot numbers in eeprom address space)
 */
#define EEPROM_VERSION		0	// v1 = '1'
#define EEPROM_MAGIC		1	// later, replace this w/ a 2-byte CRC
#define EEPROM_POWER		2	// last-used power on/off setting

#define EEPROM_VOLUME		3	// used only via serial 'console'

#define EEPROM_VOL_CMD		601	// write enum codes to this
					// virtual EEPROM addr

#define VOL_CMD_NULL		0
#define VOL_CMD_UP_SLOW		1
#define VOL_CMD_UP_FAST		2
#define VOL_CMD_DOWN_SLOW	3
#define VOL_CMD_DOWN_FAST	4

#define EEPROM_INPUT_SEL	4	// last-used input selector
#define EEPROM_OUTPUT_SEL	5	// last-used output selector
#define EEPROM_OUTPUT_SEL_MASK	6	// last-used output selector-mask
					// (bitmask version)
#define EEPROM_OUTPUT_RB_TB	7

#define EEPROM_SLEEP_INTERVAL	8	// 1..99
#define EEPROM_POWERON_DELAY	9	// 0..90


// build-time options
#define EEPROM_NUM_RELAYS	10	// 6..8
#define EEPROM_DB_STEPSIZE	11	// 0,1,2 enum values only

#define EEPROM_MOTOR_ENABLED	12	// 0=no(default), 1=installed
#define EEPROM_POT_ENABLED	13	// 0=no, 1=enabled (default)
#define EEPROM_DS1302_INSTALLED	14	// 0=no, 1=installed (default)

//#define EEPROM_X10_ENABLED	15	// 0,1
//#define EEPROM_IRTX_ENABLED	16	// 0,1

#define EEPROM_NUM_DELTA1_BOARDS 17	// 0..3
#define EEPROM_NUM_DELTA2_BOARDS 18	// 0..2

#define EEPROM_MENU_PGNUM	19	// the last-used menu page #
#define EEPROM_MENU_NODENUM	20	// the last-used menu item #

#define EEPROM_DISPLAY_SIZE	21	// 0(default)=16x2; 1=20x2,
					// 2=40x2, 3=20x4

#define EEPROM_DISPLAY_LCD_VFD	22	// 0(default)=lcd; 1=vfd

#define EEPROM_BACKLIGHT_MIN	23	// our 'lowest' setting
#define EEPROM_BACKLIGHT_MAX	24	// our 'brightest' setting

#define EEPROM_BACKLIGHT_MODE	25	// our current backlight mode

#define EEPROM_DISPLAY_MODE	26	// our current display mode
#define EEPROM_DISP_MODE_BARGRAPH 1	// next(1) = 2
#define EEPROM_DISP_MODE_BIGFONTS 2	// next(2) = 3
#define EEPROM_DISP_MODE_SLEEP    3	// next(3) = 4
#define EEPROM_DISP_MODE_CLOCK    4	// next(4) = 1

// note, these are 'virtual' and any attempted reads to these will
// really come from RTC chip
// attempts to write to them should also go to the RTC chip
#define EEPROM_TIME_HH		27	// hours
#define EEPROM_TIME_MM		28	// mins
#define EEPROM_TIME_SS		29	// secs

// a 'coarse' volume adjustment.  this is user-settable and
// defaults to 6dB jumps
#define EEPROM_VOLSTEP_COARSE	30	// typically bound to up/down arrows

// a window size on the volume control.  this defines the 'lock to lock'
// range of the motor/pot as well as the min and max 'arrow key ranges'.
// min is usually a 'mute level' and max is a safety level that you never
// want to exceed.
#define EEPROM_VOL_MIN_LIMIT	31	// mute,min level (min of window)
#define EEPROM_VOL_MAX_LIMIT	32	// max level (max of window)

// block of 8 port 'last used' volume values
// element size: 1 byte
#define EEPROM_PORT_VOL_BASE	50
//#define PORT1			51
//#define PORT2			52
//#define PORT3			53
//#define PORT4			54
//#define PORT5			55
//#define PORT6			56
//#define PORT7			57
//#define PORT8			58

// block of 8 port 'state' values (in, out, disabled)
//  element size: 1 byte
#define EEPROM_PORT_STATE_BASE	60
//#define PORT1			61
//#define PORT2			62
//#define PORT3			63
//#define PORT4			64
//#define PORT5			65
//#define PORT6			66
//#define PORT7			67
//#define PORT8			68

/*
 * PORT NAMES
 *  block of 8*8 (eight 8-char strings)
 */
#define EEPROM_PORTS_TABLE_BASE	70	// first=70, last=133
#define EEPROM_PORTS_TABLE_SIZE	( EEPROM_PORTS_TABLE_BASE + 8*8 )

/*
 * i2c address block
 */

// these are the i2c addresses we use to talk to the d1 & d2 boards
// they are in pairs; an ADDR+ and an ADDR- byte for each board
// we support a max of 2 d1 boards and 2 d2 boards for v1.0 of volu-master

// d1
#define EEPROM_I2C_D1_B1_H	150	// B0111111 (delta1 board1 ADDR+)
					// (or PGA PE addr)
#define EEPROM_I2C_D1_B1_L	151	// B0111110 (delta1 board1 ADDR-)

#define EEPROM_I2C_D1_B2_H	152	// B0111101 (delta1 board2 ADDR+)
#define EEPROM_I2C_D1_B2_L	153	// B0111100 (delta1 board2 ADDR-)

// d2
#define EEPROM_I2C_D2_B1_H	154	// B0111011 (delta2 board1 ADDR+)	
					// (or spdif PE addr)
#define EEPROM_I2C_D2_B1_L	155	// B0111010 (delta2 board1 ADDR-)

#define EEPROM_I2C_D2_B2_H	156	// B0111001 (delta2 board2 ADDR+)
#define EEPROM_I2C_D2_B2_L	157	// B0111000 (delta2 board2 ADDR-)

// the currently active bank of IR codes
#define EEPROM_IR_LEARNED_BANK_SEL 199	// 0=invalid, 1=bank1, 2=bank2

// IR learned keycodes (as 4-byte longwords, each) are stored here.
// table is MAX_FUNCTS deep, with each record being 4 bytes.
// currently, MAX_FUNCTS is 23 and so 23*4=92 (92 bytes taken up in
// EEPROM out of 1024bytes max on arduino)

// first bank of IR codes
#define EEPROM_IR_LEARNED_BASE_BANK1 200   // last byte = 292

// 2nd (alternate) bank of IR codes (not currently used)
//#define EEPROM_IR_LEARNED_BASE_BANK2 400 // last byte = 492

#define EEPROM_IR_LEARNED_BASE_BANK	EEPROM_IR_LEARNED_BASE_BANK1

#define EEPROM_USER_BANNER_BASE	500	// last byte = 531
#define EEPROM_USER_BANNER1	(EEPROM_USER_BANNER_BASE + 0*LEN_BANNER_STRING)
#define EEPROM_USER_BANNER2	(EEPROM_USER_BANNER_BASE + 1*LEN_BANNER_STRING)
#define EEPROM_USER_BANNER_SIZE	(LEN_BANNER_STRING * 2)

// end EEPROM defs


/*
 * enum values
 */
// system power
#define POWER_OFF		0
#define POWER_ON		1

// regular 'run mode' or menu mode
#define TOPLEVEL_MODE_NORMAL	1	// for non-menu (normal runtime) mode
#define TOPLEVEL_MODE_MENU	2	// the menu mode

// input/output (delta2) port states
#define PORT_AS_OUTPUT		0	// port is output
#define PORT_AS_INPUT		1	// port is input
#define PORT_AS_DISABLED	2	// port is disabled

// for output-ports, only
#define OUTPUT_MODE_RADIO	0	// radio button style
					// (only 1 on at a time)
#define OUTPUT_MODE_TOGGLE	1	// toggle button style
					// (many on at a time)

// realtime clock chip
#define RTC_UNINSTALLED		0
#define RTC_INSTALLED		1

// states of motor-pot logic
#define MOTOR_INIT		1
#define MOTOR_SETTLED		2	// motor pot is at resting state
#define MOTOR_IN_MOTION		3	// motor pot is moving right now
#define MOTOR_COASTING		4	// motor pot just passed its
					// destination and motor current
					// is released

// how fast do we want the volume to jump on the
// 'fast-up' or 'fast-down' IR press
#define DEFAULT_VOL_COARSE_INCR	6	// this is in 0.5 db steps (6dB)

// vol control enum value equates
#define VC_DOWN			1
#define VC_UP			2

#define VC_SLOW			1	// volume 'slow' (native clicks)
#define VC_FAST			2	// volume 'fast' (user-defined jumps)

#define VOL_DELAY_SHORT		20	// auto-repeat IR delay period

// how the user configures the volume engine
#define DB_STEPSIZE_TENTH	0	// 0.1dB steps
#define DB_STEPSIZE_HALF	1	// 0.5dB steps
#define DB_STEPSIZE_WHOLE	2	// 1dB steps

// relay timing for latching relays
#define PREMUTE_CLICK_DOWN_DELAY 3700
#define CLICK_DOWN_DELAY	3700	// ~4ms
#define CLICK_UP_DELAY		3700	// ~4ms

#define ANALOG_POT_MIN_RANGE	0	// min value on the a/d of the arduino
#define ANALOG_POT_MAX_RANGE	1023	// max value on the a/d of the arduino

#define NATIVE_VOL_RATE		1	// our 'small step' is always the
					// native click-size of the engine
#define POT_CHANGE_THRESH	3	// it has to be more than this
					// to register as a pot 'twist'
#define POT_REREADS		10	// re-read the pot many times to
					// weed out noise (averaging)

/*
 * time values
 */
#define DEFAULT_POWER_ON_AMP_DELAY (7)	// in seconds
#define DEFAULT_SLEEP_INTERVAL	(60)	// in minutes

#endif // _VOLCONTROL_H_

