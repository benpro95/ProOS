#line 1 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\sources\\vm_4_20 (6 relay)\\config.h"
/*
 *  @(#)config.h	1.11 16/01/04
 *
 *  config.h: compile-time feature configuration
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
 
#ifndef _CONFIG_H_
#define _CONFIG_H_

/*
 * DEBUG switches
 */

//#define DEBUG_IR1		1	// spy on the IR codes being received
//#define DEBUG_SENSED_POT	1	// see the values as you turn the pot
//#define USE_SOFTSERIAL_UART	1	// for debug
//#define USE_SERIAL_UART	1	// for debug
//#define USE_MEM_CHECKER	1	// to see free RAM left at runtime

/*
 * FEATURE switches: these enable/disable code (and feature) sections
 */

// This is used to enable LED13 to blink when an IR code was received
// (feedback to the user)
#define APP_BLINK_ON_LED13	1

// Enable more IR protocols than Sony (NEC, RC5, RC6)
#define NON_SONY		1

// Enable 'big fonts' for some displays
#define USE_BIGFONTS		1
#define USE_THICKER_BIGFONT	1	// thicker alternate big font

// Volume control plugins (pick one or more)
#define USE_D1_RELAYS		1	// latching relays for vol control
//#define USE_PGA_I2C		1	// support PGA over I2C

// I/O selector plugins (pick one or more)
#define USE_D2_RELAYS		1	// latching relays for I/O selector
//#define USE_SPDIF		1	// support I/O selector with
					//'SPDIF mask,addr' types

// Use an analog linear potentiometer for volume and other functions
#define USE_ANALOG_POT		1	// linear pot

// The potentiometer is motorized (define USE_ANALOG_POT with this one)
#define USE_MOTOR_POT		1	// motor is via h-bridge driver

// Our roles (all combos are valid)
#define BE_VOL_CONTROL		1	// show/change volume db and bargraph
#define BE_IO_SWITCH		1	// show/select in/out port names

// How much time before dimming the display when in auto-dim mode
#define DISPLAY_AUTODIM_TIME	10	// in seconds

#define ALWAYS_SHOW_SLEEP       0	// show 'S--' or a blank field
					// when sleep is not enabled

// enable the DS1302 realtime clock chip (recommended)
//#define USE_DS1302_RTC		1	// realtime clock + supercap

// Enable ONE of these for power control (X10 is not supported in v1.0x)
#define USE_POWER_RELAY		1	// SSR or bufferd relay
//#define USE_X10		1	// x10 'firecracker' wireless

// PCF8574 I2C PE chip is used in these configurations
// This shouldn't be modified
#if defined(USE_D1_RELAYS) || defined(USE_D2_RELAYS) || defined(USE_PGA_I2C)
#define USE_PCF8574		1
#endif

/*
 * Factory defaults
 */

#define DEFAULT_DELTA1_BOARD_COUNT	1
#define DEFAULT_DELTA2_BOARD_COUNT	1
#define DEFAULT_RELAY_COUNT		6	// usually 8 relays installed
#define DEFAULT_DB_STEPSIZE    DB_STEPSIZE_WHOLE
//#define DEFAULT_DB_STEPSIZE		DB_STEPSIZE_HALF

#define DEFAULT_DELTA1_I2C_ADDR_0	B0111111	// 63
#define DEFAULT_DELTA1_I2C_ADDR_1	B0111110	// 62
#define DEFAULT_DELTA1_I2C_ADDR_2	B0111101	// 61
#define DEFAULT_DELTA1_I2C_ADDR_3	B0111100	// 60

#define DEFAULT_DELTA2_I2C_ADDR_0	B0111011	// 59
#define DEFAULT_DELTA2_I2C_ADDR_1	B0111010	// 58
#define DEFAULT_DELTA2_I2C_ADDR_2	B0111001	// 57
#define DEFAULT_DELTA2_I2C_ADDR_3	B0111000	// 56

/*
 * PGA and SPDIF engine addresses.
 *  pga is bit-banged SPI over I2C.  only 1 I2C address is used for PGA.
 *  the first volume slot (I2C array index) is used for pga.
 *  for spdif, it also needs only 1 I2C addr.  it uses the first one
 *  that the d2 would use (but again, it does not need a pair like the d2
 *  uses).
 */

#ifdef SHIFT_PGA_SPDIF_TO_TOP_OF_RANGE
#define I2C_PGA_ADDR_SLOT               6
#define I2C_SPDIF_ADDR_SLOT             7
#else  // our default/recommended config
#define I2C_PGA_ADDR_SLOT               0	// start of volume group
#define I2C_SPDIF_ADDR_SLOT             4	// start of I/O group
#endif

#endif // _CONFIG_H_

