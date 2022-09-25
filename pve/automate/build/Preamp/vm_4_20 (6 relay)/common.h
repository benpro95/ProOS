/*
 *  @(#)common.h	1.8 16/12/19
 *
 *  common.h: common definitions, global functions and variables
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

#ifndef _COMMON_H_
#define _COMMON_H_

#include <ctype.h>
#include <inttypes.h>
#include <string.h>
#include <math.h>

#include <avr/io.h>
#include <avr/sleep.h>
#include <avr/eeprom.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

#include <util/delay.h>
#include <util/atomic.h>

// Volu-Master version number
#ifndef PROG_VER
#define PROG_VER		"4.02"  // must be 4-characters long
#endif

#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#include "WConstants.h"
#endif  

#include "Wire.h"
#include "EEPROM.h"

#ifdef USE_SOFTSERIAL_UART
#include "SoftwareSerial.h"
#endif

#include "config.h"
#include "lcd1_libs.h"
#include "volcontrol.h"

/*
 * What BE_VOL_CONTROL and BE_IO_SWITCH actually does
 */

#ifndef BE_VOL_CONTROL
#undef USE_D1_RELAYS
#undef USE_PGA_I2C
#endif

#ifndef BE_IO_SWITCH
#undef USE_D2_RELAYS
#undef USE_SPDIF
#endif

/*
 * Size and type of display (currently only 16x2 LCD is supported)
 */
#define DISPLAY_SIZE_16_2	0
#define DISPLAY_SIZE_20_2	1
#define DISPLAY_SIZE_40_2	2
#define DISPLAY_SIZE_20_4	3

#define DISPLAY_TYPE_LCD	0
#define DISPLAY_TYPE_VFD	1

#define DEFAULT_DISPLAY_SIZE	DISPLAY_SIZE_16_2
#define DEFAULT_DISPLAY_TYPE	DISPLAY_TYPE_LCD

/*
 * Arduino pins (offical for LCDuino-1 for Volu-Master)
 */

#define _A0_PIN				0	// unused
#define SENSED_ANALOG_POT_INPUT_PIN	1	// analog pot sense
#define CLK1302_PIN			2	// DS1302 clock (1302 pin-7)
#define DAT1302_PIN			3	// DS1302 i/o (1302 pin-6)
#define IR_TX_PIN			3	// when not using RTC,
						// this is the IR blaster pin
#define CE1302_PIN			4	// DS1302 CE (1302 pin-5)
#define _D5_PIN				5	// unused
#define _D6_PIN				6	// unused
#define RELAY_POWER_PIN			7	// power SSR 5V relay trigger
#define IR_PIN				8	// IR Sensor data-out pin to us
#define PWM_BACKLIGHT_PIN		9	// pwm-controlled LED backlight
#define X10_RTS_PIN			10	// RTS for C17A - DB9 pin 7
#define X10_DTR_PIN			11	// DTR for C17A - DB9 pin 4
#define _D12_PIN			12	// unused
#define LED13				13	// Arduino standard
#define MOTOR_POT_ROTATE_CW             16      // motor pot control
#define MOTOR_POT_ROTATE_CCW            17	// motor pot control

/*
 * extern/global vars (mostly things defined in the main .ino file)
 */

extern const char	fl_st_MUTE[];	// PROGMEM = "Mute";

// volume control
extern byte		power;
extern byte		toplevel_mode;	// 0=main mode, all others sub-modes
extern byte		mute;
extern byte		volume;

extern signed char	input_selector;
extern signed char	output_selector;
extern signed char	last_saved_out_sel;
extern signed char	old_port;	// for port change events

extern byte		output_selector_mask;
extern byte		last_saved_out_sel_mask;
extern byte		output_mode_radio_or_toggle;

extern byte		max_vol;
extern byte		min_vol;
extern byte		vol_span;
extern byte		max_byte_size;
extern byte		vol_coarse_incr;

extern unsigned long	eewrite_cur_vol_ts;
extern byte		eewrite_cur_vol_dirtybit;
extern byte		eewrite_cur_vol_value;

extern byte		installed_relay_count;
extern byte		option_db_step_size;
extern byte		option_pot_installed;
extern byte		option_motor_pot_installed;
extern byte		option_delta1_board_count;
extern byte		option_delta2_board_count;
extern byte		option_ds1302_rtc_installed;

extern int		last_seen_pot_value;	// range from 0..1023
extern byte		last_seen_IR_vol_value;
extern byte		last_volume; 
extern byte		pot_state;

extern byte		display_mode_clock;
extern byte		display_mode;
extern byte		big_mode;

extern byte		sleep_mode;
extern unsigned long	sleep_start_time;
extern int		half_minutes;
extern int		last_sleep_time_display_minutes;

extern unsigned long	last_clock_update;
extern signed char	last_secs;
extern signed char	last_mins;
extern signed char	last_hrs;

// allow for 3*2 + 2*2 = 10, which is 3 d1 and 2 d2 boards
extern byte		delta_i2c_addr[/*10*/];

/*
 * globally visible functions
 */

extern void		update_alternate_clock_display(byte admin_flag);
extern void		update_sleep_display_time(byte admin_flag);
extern void		common_startup(byte admin_forced_flag);

extern void		draw_selector_string(void);
extern void		change_io_selectors(void);
extern void		change_input_selector(byte new_in_sel);
extern void		change_output_selector(byte new_out_sel, byte new_out_sel_mask);

extern byte		reverse_bit_order(byte flag);
extern void		update_delta2_state(byte flag);
extern void		do_relay_latching(byte pcf_a, byte pcf_b,
				byte pcf_c, byte pcf_d,
				byte relays, byte forced);
extern void		relay_common_delay_then_release(
				byte pcf_a, byte pcf_b,
				byte pcf_c, byte pcf_d);

extern void		motor_pot_logic(void);
extern void		analog_sensed_pot_logic(void);
extern void		handle_analog_pot_value_changes(void);
extern int		read_pot_volume_value_with_clipping(
				int sensed_pot_value);
extern int		read_analog_pot_with_smoothing(
				byte analog_port_num, byte reread_count);

extern void		redraw_volume_display(
				byte vol_byte, byte forced_admin_flag);
extern void		redraw_volume_display_smallfonts(
				byte vol_byte, byte forced_admin_flag);
extern void		redraw_volume_display_bigfonts(byte vol_byte);

extern void		cache_flush_save_current_vol_level(
				byte forced_admin_flag);
extern void		update_volume(byte volume, byte admin_forced_flag);
extern void		vol_change_relative(byte dir_flag, byte speed_flag);
extern void		send_vol_to_all_delta1_boards(
				byte vol_byte, byte forced_update_flag);
extern void		send_vol_byte_to_engines(
				byte vol_byte, byte forced_admin_flag);

extern void		draw_graphic_bar(char *dest_buf, int value,
				int total_bargraph_size);
extern void		format_volume_to_string_buf(
				byte volume, char *ascii_vol_buf);
extern void		pad_string_buf_with_spaces(byte count);

extern void		set_port_state(byte port_num, byte state);
extern byte		get_port_state(byte port_num);

extern void		recache_data_index_and_type(void);

#endif // _COMMON_H_

