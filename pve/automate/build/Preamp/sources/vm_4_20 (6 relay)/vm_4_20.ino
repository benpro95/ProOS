/*
 *  @(#)vm_1_02.ino	1.21 3/26/18 modified by Ben Provenzano III
 *  ** Designed for HiFi Preamp V4 **
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

#include "common.h"

#include "Wire.h"
#include "EEPROM.h"

/*
 * forward defs
 */

void		setup(void);
void		loop(void);

void		init_system(void);

void		format_output_port_state_char(byte port_num_mask, char *dest_string_buf);

void		power_on_off_countdown(byte up_down_flag);
void		power_off_logic(void);
void		power_on_logic(byte config_button_flag);

void		turn_on_power_relay(void);
void		turn_off_power_relay(void);

void		resync_display_mode(void);
void		common_startup(byte admin_forced_flag);
void		print_output_port_state_char(byte port_num);
void		redraw_selector_string(void);
void		redraw_clock(byte admin_forced, byte show_second_hand);
void		handle_sleep_mode_timeslice(void);
void		update_sleep_display_time(byte admin_flag);
void		update_alternate_clock_display(byte admin_flag);
void		show_port_change_event(char *old_s, char *new_s);
void		toggle_mute(void);
void		blink_led13(byte on_off_flag);
void		get_and_draw_logo_line(byte logo_line_num);

unsigned long	get_IR_key(void);
void		handle_IR_keys_normal_mode(void);
void		handle_IR_keys_menu_mode(void);
void		ir_key_dump(byte line_num);

void		port_common(byte port_num);
void		input_port_common(byte port_num);
void		output_port_common(byte port_num);
void		notify_user_1(const char* PROGMEM message, int screen_pos);
void		notify_user_2(const char* PROGMEM message, int screen_pos);

byte		scan_front_button(void);
void		signon_msg(void);
byte		check_config_button_with_timeout(void);
void		redraw_IR_prompt_string(int idx);
void		enter_config_mode(void);

void		init_port_structs_eeprom(void);
void		init_all_eeprom(void);
void		recalc_volume_range(void);

void		eeprom_read_port_name(int port_num);
void		eeprom_read_banner_name(int banner_num);

void		read_eeprom_oper_values(void);
void		read_IR_learned_keys_from_eeprom(void);

void		menu_draw_label(void);
void		menu_init_string(void);
void		menu_draw_string(byte blink_flag);
void		menu_draw_int(byte blink_flag);
void		menu_draw_data(byte blink_flag);
void		menu_find_start_of_word(void);
int		menu_find_data_len(void);
void		menu_find_end_of_word(void);
void		menu_find_prev_data_field(void);
void		menu_find_next_data_field(void);
void		menu_draw_screen(byte screen_idx);
void		init_blink_state(void);
void		toggle_blink_state(void);
void		flash_string_to_RAM(byte str_table_index, byte table_name);
void		flash_string8_to_RAM(byte str_table_index, byte table_name);
void		leaving_field_saving_data(void);
void		valuator_byte_update(byte temp_valuator);
void		pad_string_buf_with_spaces(byte count);

void		cycle_between_display_modes(void);
void		cycle_between_backlight_modes(void);
void		cycle_between_sleep_modes(void);
void		cycle_between_output_toggle_radio_modes(void);

int		search_eeprom_for_IR_code(void);  // key_code is global
void		processing_while_system_is_off(void);


/*
 * 'flash string table' string literals.
 *   on the arduino, keeping strings in FLASH can save run-ram
 */

const char	fl_st_romTitle[]	PROGMEM  = "ProDesigns";
const char	fl_st_romVersion[]	PROGMEM  = "HiFi Preamp " PROG_VER;

// IR learn key names
const char	fl_st_up_fast[]		PROGMEM = "Up Arrow";    //"Up Fast";
const char	fl_st_down_fast[]	PROGMEM = "Down Arrow";  //"Dn Fast";
const char	fl_st_up_slow[]		PROGMEM = "Right Arrow"; //"Up Slow";
const char	fl_st_down_slow[]	PROGMEM = "Left Arrow";  //"Dn Slow";
const char	fl_st_mute[]		PROGMEM = "Mute";

const char	fl_st_up_alias[]	PROGMEM = "Up Alias";
const char	fl_st_down_alias[]	PROGMEM = "Down Alias";

const char	fl_st_power[]		PROGMEM = "Power";
const char	fl_st_menu[]		PROGMEM = "Menu";
const char	fl_st_sleep[]		PROGMEM = "Sleep";
const char	fl_st_backlight[]	PROGMEM = "Backlight";
const char	fl_st_display1[]	PROGMEM = "Display";

// these are hard-bound to keys 1..8
const char	fl_st_one[]		PROGMEM = "1";
const char	fl_st_two[]		PROGMEM = "2";
const char	fl_st_three[]		PROGMEM = "3";
const char	fl_st_four[]		PROGMEM = "4";
const char	fl_st_five[]		PROGMEM = "5";
const char	fl_st_six[]		PROGMEM = "6";
const char	fl_st_seven[]		PROGMEM = "7";
const char	fl_st_eight[]		PROGMEM = "8";

// the 2 extra keypad keys
const char	fl_st_nine[]		PROGMEM = "9";
const char	fl_st_zero[]		PROGMEM = "0";

const char	fl_st_multiout[]	PROGMEM = "Multi-Out";

// (end of IR learn key prompts)


/*
 * volume control area
 * used in menu mode screens.
 */

// volume control engine select
const char	fl_st_d1_boards[]	PROGMEM = "Volume";

// delta1: 1,2 boards
const char	fl_st_vol_eng_d1_1[]	PROGMEM = "1 d1  ";
const char	fl_st_vol_eng_d1_2[]	PROGMEM = "2 d1  ";

// PGA (chip count does not matter)
const char	fl_st_vol_eng_pga_1[]	PROGMEM = "PGA   ";

// mute
const char	fl_st_MUTE[]		PROGMEM = "MUTE";


/*
 * i/o selector area
 * used in menu mode screens.
 */

// i/o selector engine select
const char	fl_st_d2_boards[]	PROGMEM = "I/O sel";

// delta2: 1,2
const char	fl_st_io_eng_d2_1[]	PROGMEM = "1 d2   ";
const char	fl_st_io_eng_d2_2[]	PROGMEM = "2 d2   ";

// spdif via binary-addr OR via bitmask
const char	fl_st_io_eng_spdif_addr[] PROGMEM = "S-Addr ";
const char	fl_st_io_eng_spdif_mask[] PROGMEM = "S-Mask ";

const char	fl_st_mode[]		PROGMEM = " ";

const char	fl_st_num_relays[]	PROGMEM = "d1 Relays";
const char	fl_st_db_stepsize[]	PROGMEM = "dB/Step";

const char	fl_st_db_tenth[]	PROGMEM = "0.1 dB";
const char	fl_st_db_half[]		PROGMEM = "0.5 dB";
const char	fl_st_db_whole[]	PROGMEM = "1 dB";

const char	fl_st_motor_opt[]	PROGMEM = "Motor";
const char	fl_st_pot_opt[]		PROGMEM = "Pot";
const char	fl_st_clock_opt[]	PROGMEM = "Clock";

const char	fl_st_vol_step[]	PROGMEM = "Volume Step";
const char	fl_st_vol_step_coarse[]	PROGMEM = "Coarse";

const char	fl_st_min[]		PROGMEM = "Min";
const char	fl_st_max[]		PROGMEM = "Max";

const char	fl_st_amp_delay[]	PROGMEM = "Amp Delay";

const char	fl_st_minvol[]		PROGMEM = "MinVol";
const char	fl_st_maxvol[]		PROGMEM = "MaxVol";

const char	fl_st_userbanner1[]	PROGMEM = "Banner 1";
const char	fl_st_userbanner2[]	PROGMEM = "Banner 2";

const char	fl_st_time_colon[]	PROGMEM = ":";

const char	fl_st_d1_1[]		PROGMEM = "d1-1";
const char	fl_st_d1_2[]		PROGMEM = "d1-2";

const char	fl_st_d2_1[]		PROGMEM = "d2-1";
const char	fl_st_d2_2[]		PROGMEM = "d2-2";

const char	fl_st_H[]		PROGMEM = " "; // "H";
const char	fl_st_L[]		PROGMEM = " "; // "L";

const char	fl_st_completed[]	PROGMEM = "Completed.";
const char	fl_st_saving[]		PROGMEM = "Saving...";
const char	fl_st_unchanged[]	PROGMEM = "Unchanged.";
const char	fl_st_keyskipped[]	PROGMEM = "Key Skipped.";
const char	fl_st_config_mode[]	PROGMEM = "Config Mode!";
const char	fl_st_restore_def[]	PROGMEM = "Restore Default?";
const char	fl_st_init_eeprom[]	PROGMEM = "Init EEPROM now.";
#ifdef DEBUG_IR1
const char	fl_st_IR_diag[]		PROGMEM = "Debug IR";
#endif
const char	fl_st_learn_ir[]	PROGMEM = "Learn IR";
const char	fl_st_goodnight[]	PROGMEM = "Good night";
const char	fl_st_status_on[]	PROGMEM = " On  ";
const char	fl_st_status_off[]	PROGMEM = " Off ";
const char	fl_st_status_auto[]	PROGMEM = " Auto";
const char	fl_st_input[]		PROGMEM = "Input";
const char	fl_st_output[]		PROGMEM = "Output";
const char	fl_st_na[]		PROGMEM = "n/a";

const char	fl_st_port1[]		PROGMEM = "Port-1";
const char	fl_st_port2[]		PROGMEM = "Port-2";
const char	fl_st_port3[]		PROGMEM = "Port-3";
const char	fl_st_port4[]		PROGMEM = "Port-4";
const char	fl_st_port5[]		PROGMEM = "Port-5";
const char	fl_st_port6[]		PROGMEM = "Port-6";
const char	fl_st_port7[]		PROGMEM = "Port-7";
const char	fl_st_port8[]		PROGMEM = "Port-8";

const char	fl_st_null[]		PROGMEM = "";


// flash string table (menu screen labels)
// screen edit strings

const char*  const fl_st_screen_fields[] PROGMEM = {
/*  0 */	fl_st_num_relays,
/*  1 */	NULL,	// fl_st_starting_bit,
/*  2 */	fl_st_db_stepsize,

/*  3 */	fl_st_motor_opt,
/*  4 */	fl_st_pot_opt,
/*  5 */	fl_st_clock_opt,

/*  6 */	NULL,	//fl_st_bl_min,
/*  7 */	NULL,	//fl_st_bl_max,
/*  8 */	NULL,	//fl_st_bl_auto,

/*  9 */	NULL,	//fl_st_sleep_c,

/* 10 */	fl_st_vol_step,
/* 11 */	NULL,	// fl_st_vol_step_sm,
/* 12 */	fl_st_vol_step_coarse,

/* 13 */	fl_st_min,
/* 14 */	fl_st_max,

		// start of port names
/* 15 */	fl_st_port1,
/* 16 */	fl_st_port2,
/* 17 */	fl_st_port3,
/* 18 */	fl_st_port4,
/* 19 */	fl_st_port5,
/* 20 */	fl_st_port6,
/* 21 */	fl_st_port7,
/* 22 */	fl_st_port8,

/* 23 */	fl_st_d1_boards,
/* 24 */	fl_st_d2_boards,
/* 25 */	NULL,

/* 26 */	fl_st_amp_delay,
/* 27 */	fl_st_sleep,

/* 28 */	fl_st_backlight,

/* 29 */	fl_st_minvol,
/* 30 */	fl_st_maxvol,

		// factory shipped version strings
/* 31 */	fl_st_romTitle,
/* 32 */	fl_st_romVersion,

		// user-changeable banner names
/* 33 */	fl_st_userbanner1,
/* 34 */	fl_st_userbanner2,

/* 35 */	fl_st_time_colon,

/* 36 */	fl_st_d1_1,
/* 37 */	fl_st_d1_2,

/* 38 */	fl_st_d2_1,
/* 39 */	fl_st_d2_2,

/* 40 */	fl_st_H,
/* 41 */	fl_st_L,

/* 42 */	fl_st_mode,	// port mode (0,1,2)

/* 43 */	fl_st_null
};

// The following must match the fl_st_screen_fields[] table above.
#define ROMTITLE_STRING_IDX	31
#define ROMVERSION_STRING_IDX	32


/*
 * instance of the port expander 'class'.  i2c addr's are stored in an
 * array of bytes.  the same instance 'pcf' and a varying delta_i2c_addr[]
 * entry fully describe an i2c target.
 */
#ifdef USE_PCF8574
PCF8574		pcf = PCF8574();
#endif

#if defined(USE_D1_RELAYS) || defined(USE_D2_RELAYS) || \
    defined(USE_PGA_I2C) || defined(USE_SPDIF)
// allow for 3*2 + 2*2 = 10, which is 3 d1 and 2 d2 boards
byte	delta_i2c_addr[10];
#endif


/*
 * globals that almost everyone uses
 */

byte		installed_relay_count;
byte		option_db_step_size;
byte		option_pot_installed;
byte		option_motor_pot_installed;
byte		option_delta1_board_count;
byte		option_delta2_board_count;
byte		option_ds1302_rtc_installed;

int		last_seen_pot_value;	// raw values range from 0..1023
byte		last_seen_IR_vol_value;
byte		last_volume;		// the last volume value
byte		pot_state;

byte		power;
byte		toplevel_mode;
byte		mute;
byte		volume;

signed char	input_selector = -1;
signed char	output_selector = -1;
signed char	last_saved_out_sel = -1;
signed char	old_port = -1;		// for port-change events
byte		old_port_mask;
byte		output_selector_mask;
byte		last_saved_out_sel_mask;
byte		output_mode_radio_or_toggle;

byte		min_vol;
byte		max_vol;
byte		vol_span;
byte		max_byte_size;
byte		vol_coarse_incr;

// cached volume logic (don't write to EEPROM too fast)
unsigned long	eewrite_cur_vol_ts;	// = millis();
byte		eewrite_cur_vol_dirtybit; // FALSE;
byte		eewrite_cur_vol_value;


/*
 * global buffer that anyone can use (for short term)
 */
char		string_buf[STRING_BUF_MAXLEN];


/*
 * host-mode support
 */

// softserial is not supported yet
#ifdef USE_SOFTSERIAL_UART
// software serial port
#define rxPin			0	// 2
#define txPin			1	// 3
//	pinMode(rxPin, INPUT);
//	pinMode(txPin, OUTPUT);
SoftwareSerial	software_serial = SoftwareSerial(rxPin, txPin);
#endif

// hardware uart serial
#ifdef USE_SERIAL_UART
#define SERIAL_UART_BUF_LEN	20
char		serial_uart_buffer[SERIAL_UART_BUF_LEN+1];
byte		uart_buffer_idx;
char		four_byte_buffer[4];
int		ee_addr;
byte		ee_val;
#endif


/*
 * create an instance (and have it init itself) of the real time clock
 */
#ifdef USE_DS1302_RTC
DS1302		rtc = DS1302();
byte		my_hrs;
byte		my_mins;
byte		my_secs;
#endif


/*
 * for sleep-timer (don't need the RTC chip for this, btw)
 */
byte		sleep_mode;
unsigned long	sleep_start_time;
int		half_minutes;
int		last_sleep_time_display_minutes;

unsigned long last_clock_update;
signed char	last_secs;
signed char	last_mins;
signed char	last_hrs;


/*
 * display modes
 */
byte		display_mode_clock;	// toggle value (0,1) to show
					// vol dB or clock time
#ifdef USE_BIGFONTS
byte		big_mode;		// lcd big fonts flag
#endif

byte		display_mode;		// current display mode


/*
 * menu tree structs
 */

// note, labels do not exist in EEPROM.  EEPROM has things that the user
// can edit and re-save.  labels are fixed in FLASH and so they do not
// have an 'eeprom_addr' field in this struct.

typedef struct {
	// location (x,y)
	byte	line;		// 1..2
	byte	col;		// 1..16

	int	st8_addr;	// addr in 'fl_st_screen_fields'
				// flash string table
} _label_node;

_label_node label_nodes[] = {
// screen 0
/*  0 */	{ 1,  1,  0 },	// fl_st_num_relays
/*  1 */	{ 2,  1,  2 },	// fl_st_db_stepsize

// screen 1
/*  2 */	{ 1,  1,  3 },	// fl_st_motor_opt
/*  3 */	{ 2,  1,  4 },	// fl_st_pot_opt
/*  4 */	{ 2, 10,  5 },	// fl_st_clock_opt   // clock

// screen 2 (delta1,2 board_count and chip_type)
/*  5 */	{ 1,  1, 23 },	// fl_st_d1_boards
/*  6 */	{ 2,  1, 24 },	// fl_st_d2_boards

// screen 3 (amp delay, sleep timer)
/*  7 */	{ 1,  1, 26 },	// fl_st_amp_delay
/*  8 */	{ 2,  1, 27 },	// fl_st_sleep
  
// screen 4 (backlight)
/*  9 */	{ 1,  1, 28 },	// fl_st_backlight
/* 10 */	{ 2,  2, 13 },	// fl_st_min
/* 11 */	{ 2, 10, 14 },	// fl_st_max

// screen 5 (vol step large)
/* 12 */	{ 1,  1, 10 },	// fl_st_vol_step
/* 13 */	{ 2,  2, 12 },	// fl_st_vol_step_coarse

// screen 6 (minVol, maxVol)
/* 14 */	{ 1,  1, 29 },	// fl_st_minvol
/* 15 */	{ 2,  1, 30 },	// fl_st_maxvol

// screen 7 (user banner 1)
/* 16 */	{ 1,  1, 33 },	// fl_st_userbanner1

// screen 8 (user banner 2)
/* 17 */	{ 1,  1, 34 },	// fl_st_userbanner2

// screen  9 (port1 name)
/* 18 */	{ 1,  1, 15 },	// 1

// screen 10 (port2 name)
/* 19 */	{ 1,  1, 16 },	// 2

// screen 11 (port3 name)
/* 20 */	{ 1,  1, 17 },	// 3

// screen 12 (port4 name)
/* 21 */	{ 1,  1, 18 },	// 4

// screen  9 (port5 name)
/* 22 */	{ 1,  1, 19 },	// 5

// screen 10 (port6 name)
/* 23 */	{ 1,  1, 20 },	// 6

// screen 11 (port7 name)
/* 24 */	{ 1,  1, 21 },	// 7

// screen 12 (port8 name)
/* 25 */	{ 1,  1, 22 },	// 8

// screen 17 (set clock)
/* 26 */	{ 1,  1,  5 },	// fl_st_clock_opt
/* 27 */	{ 2,  5, 35 },	// ':'
/* 28 */	{ 2,  8, 35 },	// ':'

// screen 18 (d1 board1 i2c addresses)
/* 29 */	{ 1,  1, 36 },	// 'd1-1'
/* 30 */	{ 2,  1, 40 },	// dummy 'H'
/* 31 */	{ 2,  2, 41 },	// dummy 'L'

// screen 19 (d1 board2 i2c addresses)
/* 32 */	{ 1,  1, 37 },	// 'd1-2'

// screen 20 (d2 board1 i2c addresses)
/* 33 */	{ 1,  1, 38 },	// 'd2-1'

// screen 21 (d2 board2 i2c addresses)
/* 34 */	{ 1,  1, 39 },	// 'd2-2'

// port (1..8) type (in,out,x)
/* 35 */	{ 2,  1, 42 },	// 'mode'
};


typedef struct {
	// location (x,y) and length
	byte	line;		// 1..2
	byte	col;		// 1..16
	byte	len;		// often 8 or sometimes 16

	int	eeprom_addr;	// 0..255 addr of which byte in EEPROM
				// this variable corresponds to
} _textfield8_node;

_textfield8_node tf8_nodes[] = {
// screen 5 (port 1)
/*  0 */  { 2, 9, LEN_PORTNAME_STRING,
	    EEPROM_PORTS_TABLE_BASE + (LEN_PORTNAME_STRING*0) },
// screen 6 (port 2)
/*  1 */  { 2, 9, LEN_PORTNAME_STRING,
	    EEPROM_PORTS_TABLE_BASE + (LEN_PORTNAME_STRING*1) },
// screen 7 (port 3)
/*  2 */  { 2, 9, LEN_PORTNAME_STRING,
	    EEPROM_PORTS_TABLE_BASE + (LEN_PORTNAME_STRING*2) },
// screen 8 (port 4)
/*  3 */  { 2, 9, LEN_PORTNAME_STRING,
	    EEPROM_PORTS_TABLE_BASE + (LEN_PORTNAME_STRING*3) },
// screen 9 (port 5)
/*  4 */  { 2, 9, LEN_PORTNAME_STRING,
	    EEPROM_PORTS_TABLE_BASE + (LEN_PORTNAME_STRING*4) },
// screen 10 (port 6)
/*  5 */  { 2, 9, LEN_PORTNAME_STRING,
	    EEPROM_PORTS_TABLE_BASE + (LEN_PORTNAME_STRING*5) },
// screen 11 (port 7)
/*  6 */  { 2, 9, LEN_PORTNAME_STRING,
	    EEPROM_PORTS_TABLE_BASE + (LEN_PORTNAME_STRING*6) },
// screen 12 (port 8)
/*  7 */  { 2, 9, LEN_PORTNAME_STRING,
	    EEPROM_PORTS_TABLE_BASE + (LEN_PORTNAME_STRING*7) },
// top banner
/*  8 */  { 2, 1, LEN_BANNER_STRING,
	    EEPROM_USER_BANNER_BASE + (LEN_BANNER_STRING*0) },
// bottom banner
/*  9 */  { 2, 1, LEN_BANNER_STRING,
	    EEPROM_USER_BANNER_BASE + (LEN_BANNER_STRING*1) },

};

// IMPORTANT to keep these matching the tf8_nodes table above
#define PORTNAME_DATA_IDX_START		0
#define PORTNAME_DATA_IDX_END		7
#define BANNER_DATA_IDX_START		8
#define BANNER_DATA_IDX_END		9


typedef struct {
	// location (x,y) and field length
	byte	line;		// 1..2
	byte	col;		// 1..16
	byte	len;		// max length of screen_edit field,
				// in char cell positions

	int	min_legal;	// min and max values (if we choose to
				// enforce it)
	int	max_legal;

	int	default_value;	// a default value that we write to EEPROM
				// and the menu can use to init a menu field

	int	eeprom_addr;	// 0..255 addr of which byte in EEPROM
				// this variable corresponds to
} _int_node_t;

_int_node_t int_nodes[] = {

/* -----------------------------------------------------------------------
 * index line/col len min,max,def,
 * actual_variable (volatile) non-volatile perm location description
 * -----------------------------------------------------------------------*/

// screen 00
/*  0 */	{ 1, 11, 1,   5,   8,   8,
		  EEPROM_NUM_RELAYS },		// "delta1 Relays #"
/*  1 */	{ 2, 11, 6,   0,   2,   2,
		  EEPROM_DB_STEPSIZE },		// "dB/step #"  (enum value)

// screen 01
/*  2 */	{ 1,  7,  1,  0,   1,   0,
		  EEPROM_MOTOR_ENABLED },	// "Motor #"
/*  3 */	{ 2,  7,  1,  0,   1,   1,
		  EEPROM_POT_ENABLED },		// "Pot #"
/*  4 */	{ 2, 16,  1,  0,   1,   1,
		  EEPROM_DS1302_INSTALLED },	// "Clock #"

// screen 02
#ifdef USE_PGA_I2C
/*  5 */	{ 1,  9,  6,  0,   3,   1,
		  EEPROM_NUM_DELTA1_BOARDS },	// "d1 board count"
#else
/*  5 */	{ 1,  9,  6,  0,   2,   1,
		  EEPROM_NUM_DELTA1_BOARDS },	// "d1 board count"
#endif

#ifdef USE_SPDIF
/*  6 */	{ 2,  9,  6,  0,   4,   1,
		  EEPROM_NUM_DELTA2_BOARDS },	// "d2 board count"
#else
/*  6 */	{ 2,  9,  6,  0,   2,   1,
		  EEPROM_NUM_DELTA2_BOARDS },	// "d2 board count"
#endif

// screen 03
/*  7 */	{ 1, 13,  2,  0,  99,   2,
		  EEPROM_POWERON_DELAY },	// power on delay (secs)
/*  8 */	{ 2, 13,  2,  1,  99,  60,
		  EEPROM_SLEEP_INTERVAL },	// sleep time (minutes)

// screen 04
/*  9 */	{ 2,  6,  3,  0, 255, 200,
		  EEPROM_BACKLIGHT_MIN },	// backlight_min
/* 10 */	{ 2, 14,  3,  0, 255, 255,
		  EEPROM_BACKLIGHT_MAX },	// backlight_max

// screen 05
/* 11 */	{ 2,  10,  6,  1,  16,   8,
		  EEPROM_VOLSTEP_COARSE },	// vol coarse incr

// screen 06
/* 12 */	{ 1,  9,  8,  0, 255,   0,
		  EEPROM_VOL_MIN_LIMIT },	// "Min"
/* 13 */	{ 2,  9,  8,  0, 255, 255,
		  EEPROM_VOL_MAX_LIMIT },	// "Max"

// screen 17 (set clock)
/* 14 */	{ 2,  3,  2,  0,  23,  12,
		  EEPROM_TIME_HH },		// "HH"
/* 15 */	{ 2,  6,  2,  0,  59,   0,
		  EEPROM_TIME_MM },		// "MM"
/* 16 */	{ 2,  9,  2,  0,  59,   0,
		  EEPROM_TIME_SS },		// "SS"

// screen 18 (d1 board1 i2c addresses)
/* 17 */	{ 1,  6, 11, 0x00, 0x7f, B0111111,
		  EEPROM_I2C_D1_B1_H },		// i2c addr
/* 18 */	{ 2,  6, 11, 0x00, 0x7f, B0111110,
		  EEPROM_I2C_D1_B1_L },		// i2c addr

// screen 19 (d1 board2 i2c addresses)
/* 19 */	{ 1,  6, 11, 0x00, 0x7f, B0111101,
		  EEPROM_I2C_D1_B2_H },		// i2c addr
/* 20 */	{ 2,  6, 11, 0x00, 0x7f, B0111100,
		  EEPROM_I2C_D1_B2_L },		// i2c addr

// screen 20 (d2 board1 i2c addresses)
/* 21 */	{ 1,  6, 11, 0x00, 0x7f, B0111011,
		  EEPROM_I2C_D2_B1_H },		// i2c addr
/* 22 */	{ 2,  6, 11, 0x00, 0x7f, B0111010,
		  EEPROM_I2C_D2_B1_L },		// i2c addr

// screen 21 (d2 board2 i2c addresses)
/* 23 */	{ 1,  6, 11, 0x00, 0x7f, B0111001,
		  EEPROM_I2C_D2_B2_H },		// i2c addr
/* 24 */	{ 2,  6, 11, 0x00, 0x7f, B0111000,
		  EEPROM_I2C_D2_B2_L },		// i2c addr

// delta2 port 'direction' flags (in/out/disabled)
/* 25 */	{ 2,  2,  6,  0,  2,  1,
		  EEPROM_PORT_STATE_BASE+0 },	// in/out/disable
/* 26 */	{ 2,  2,  6,  0,  2,  1,
		  EEPROM_PORT_STATE_BASE+1 },	// in/out/disable
/* 27 */	{ 2,  2,  6,  0,  2,  1,
		  EEPROM_PORT_STATE_BASE+2 },	// in/out/disable
/* 28 */	{ 2,  2,  6,  0,  2,  1,
		  EEPROM_PORT_STATE_BASE+3 },	// in/out/disable
/* 29 */	{ 2,  2,  6,  0,  2,  0,
		  EEPROM_PORT_STATE_BASE+4 },	// in/out/disable
/* 30 */	{ 2,  2,  6,  0,  2,  0,
		  EEPROM_PORT_STATE_BASE+5 },	// in/out/disable
/* 31 */	{ 2,  2,  6,  0,  2,  0,
		  EEPROM_PORT_STATE_BASE+6 },	// in/out/disable
/* 32 */	{ 2,  2,  6,  0,  2,  0,
		  EEPROM_PORT_STATE_BASE+7 },	// in/out/disable
};


// The following are for the data_type field in _menu_node
#define D_NULL		0	// sentinel use
#define D_LABEL		1	// when there's a solitary label
				// and no data_field
#define D_INTEGER	2	// integer field
#define D_STRING	3	// string field

typedef struct {
	// the label or data field
	byte	data_type;	// this enum describes the next field
				// (string, int)

	// use 'data_type' to pick the right way to decode 'data_node_idx'
	byte	data_node_idx;	// index to 'variant' table
				// (int, string, bitstring)
} _menu_node;

_menu_node  menu_nodes[] = {
// screen 0 LABELS
/*  0 */	{ D_LABEL,     0 },	// "d1 Relays"
/*  1 */	{ D_LABEL,     1 },	// "dB/step"
//  screen 0 DATA
/*  2 */	{ D_INTEGER,   0 },	// "d1 Relays #"
/*  3 */	{ D_INTEGER,   1 },	// "dB/step #"

//  screen 1 LABELS
/*  4 */	{ D_LABEL,     2 },	// "Motor"
/*  5 */	{ D_LABEL,     3 },	// "Pot"
/*  6 */	{ D_LABEL,     4 },	// "Clock"
//  screen 1 DATA
/*  7 */	{ D_INTEGER,   2 },	// "Motor #"
/*  8 */	{ D_INTEGER,   3 },	// "Pot #"
/*  9 */	{ D_INTEGER,   4 },	// "Clock #"

// screen 2 LABELS
/* 10 */	{ D_LABEL,    5 },	// "d1 board count"
/* 11 */	{ D_LABEL,    6 },	// "d2 board count"
// screen 2 DATA
/* 12 */	{ D_INTEGER,  5 },	// d1_count
/* 13 */	{ D_INTEGER,  6 },	// d2_count

// screen 3 LABELS
/* 14 */	{ D_LABEL,    7 },	// "Amp delay"
/* 15 */	{ D_LABEL,    8 },	// "Sleep timer"
// screen 3 DATA
/* 16 */	{ D_INTEGER,  7 },	// amp_delay
/* 17 */	{ D_INTEGER,  8 },	// sleep_time

// screen 4 LABELS
/* 18 */	{ D_LABEL,    9 },	// "Backlight"
/* 19 */	{ D_LABEL,   10 },	// "Min"
/* 20 */	{ D_LABEL,   11 },	// "Max"
// screen 4 DATA
/* 21 */	{ D_INTEGER,  9 },	// backlight_min
/* 22 */	{ D_INTEGER, 10 },	// backlight_max
 
// screen 5 LABELS
/* 23 */	{ D_LABEL,   12 },	// "Volume Step"
/* 24 */	{ D_LABEL,   13 },	// "Coarse"
// screen 5 DATA
/* 25 */	{ D_INTEGER, 11 },	// vol_coarse_incr

// screen 6 LABELS
/* 26 */	{ D_LABEL,   14 },	// "MinVol"
/* 27 */	{ D_LABEL,   15 },	// "MaxVol"
// screen 5 DATA
/* 28 */	{ D_INTEGER, 12 },	// min_vol
/* 29 */	{ D_INTEGER, 13 },	// max_vol

// screen 7 LABELS
/* 30 */	{ D_LABEL,   16 },	// "user banner1"
// screen 7 DATA
/* 31 */	{ D_STRING,   8 },	// top name
					// (array item 8 in 'tf8_nodes[]')

// screen 8 LABELS
/* 32 */	{ D_LABEL,   17 },	// "user banner2"
// screen 8 DATA
/* 33 */	{ D_STRING,   9 },	// bottom name
					// (array item 9 in 'tf8_nodes[]')

// DUMMY data just to keep from renaming the whole rest of the array ;(
/* 34 */	{ D_LABEL,    1 },
/* 35 */	{ D_LABEL,    1 },

/*
 * i/o port data
 */

// screen 9 LABELS
/* 36 */	{ D_LABEL,   18 },	// "p1"
/* 37 */	{ D_LABEL,   35 },	// "mode"
// screen 9 DATA
/* 38 */	{ D_INTEGER, 25 },	// port1 mode
/* 39 */	{ D_STRING,   0 },	// port1 Name

// screen 10 LABELS
/* 40 */	{ D_LABEL,   19 },	// "p2"
/* 41 */	{ D_LABEL,   35 },	// "mode"
// screen 10 DATA
/* 42 */	{ D_INTEGER, 26 },	// port2 mode
/* 43 */	{ D_STRING,   1 },	// port2 Name

// screen 11 LABELS
/* 44 */	{ D_LABEL,   20 },	// "p3"
/* 45 */	{ D_LABEL,   35 },	// "mode"
// screen 11 DATA
/* 46 */	{ D_INTEGER, 27 },	// port3 mode
/* 47 */	{ D_STRING,   2 },	// port3 Name

// screen 12 LABELS
/* 48 */	{ D_LABEL,   21 },	// "p4"
/* 49 */	{ D_LABEL,   35 },	// "mode"
// screen 12 DATA
/* 50 */	{ D_INTEGER, 28 },	// port4 mode
/* 51 */	{ D_STRING,   3 },	// port4 Name

// screen 13 LABELS
/* 52 */	{ D_LABEL,   22 },	// "p5"
/* 53 */	{ D_LABEL,   35 },	// "mode"
// screen 13 DATA
/* 54 */	{ D_INTEGER, 29 },	// port5 mode
/* 55 */	{ D_STRING,   4 },	// port5 Name

// screen 14 LABELS
/* 56 */	{ D_LABEL,   23 },	// "p6"
/* 57 */	{ D_LABEL,   35 },	// "mode"
// screen 14 DATA
/* 58 */	{ D_INTEGER, 30 },	// port6 mode
/* 59 */	{ D_STRING,   5 },	// port6 Name

// screen 15 LABELS
/* 60 */	{ D_LABEL,   24 },	// "p7"
/* 61 */	{ D_LABEL,   35 },	// "mode"
// screen 15 DATA
/* 62 */	{ D_INTEGER, 31 },	// port7 mode
/* 63 */	{ D_STRING,   6 },	// port7 Name

// screen 16 LABELS
/* 64 */	{ D_LABEL,   25 },	// "p8"
/* 65 */	{ D_LABEL,   35 },	// "mode"
// screen 16 DATA
/* 66 */	{ D_INTEGER, 32 },	// port8 mode
/* 67 */	{ D_STRING,   7 },	// port8 Name
  
// screen 17 LABELS
/* 68 */	{ D_LABEL,   26 },	// 'set clock'
/* 69 */	{ D_LABEL,   27 },	// ':'
/* 70 */	{ D_LABEL,   28 },	// ':'
// screen 17 DATA
/* 71 */	{ D_INTEGER, 14 },	// hh
/* 72 */	{ D_INTEGER, 15 },	// mm
/* 73 */	{ D_INTEGER, 16 },	// ss

/*
 * i2c address table (8 addr's total)
 */

// screen 18 LABELS
/* 74 */	{ D_LABEL,   29 },	// 'd1-1'
/* 75 */	{ D_LABEL,   30 },	// 'H'
/* 76 */	{ D_LABEL,   31 },	// 'L'
// screen 18 DATA
/* 77 */	{ D_INTEGER, 17 },	// d1_1_h
/* 78 */	{ D_INTEGER, 18 },	// d1_1_l

// screen 19 LABELS
/* 79 */	{ D_LABEL,   32 },	// 'd1-2'
/* 80 */	{ D_LABEL,   30 },	// 'H'
/* 81 */	{ D_LABEL,   31 },	// 'L'
// screen 19 DATA
/* 82 */	{ D_INTEGER, 19 },	// d1_2_h
/* 83 */	{ D_INTEGER, 20 },	// d1_2_l

// screen 20 LABELS
/* 84 */	{ D_LABEL,   33 },	// 'd2-1'
/* 85 */	{ D_LABEL,   30 },	// 'H'
/* 86 */	{ D_LABEL,   31 },	// 'L'
// screen 20 DATA
/* 87 */	{ D_INTEGER, 21 },	// d2_1_h
/* 88 */	{ D_INTEGER, 22 },	// d2_1_l

// screen 21 LABELS
/* 89 */	{ D_LABEL,   34 },	// 'd2-2'
/* 90 */	{ D_LABEL,   30 },	// 'H'
/* 91 */	{ D_LABEL,   31 },	// 'L'
// screen 21 DATA
/* 92 */	{ D_INTEGER, 23 },	// d2_2_h
/* 93 */	{ D_INTEGER, 24 },	// d2_2_l

// sentinel
/* 94 */	{  D_NULL,    0 }
};

#define SCREEN_ID_SETTIME	17


// screens are complete objects that don't rely on state from previous screens
// screens are simply arrays of 'menu_nodes'

typedef struct {
	// these are forward and backward links.  you have to hand-edit
	// these numbers as you create pre-initialized structure arrays.
	byte	node_prev_idx;
	byte	node_next_idx;
  
	byte	starting_menu_node_idx;	// index from menu_nodes[] table 
	byte	ending_menu_node_idx;	// index from menu_nodes[] table 
  
	byte	starting_data_node_idx;	// range of data nodes
					// (for circling around) 
	byte	ending_data_node_idx;	// these indexes point to 'menu'
					// table items
} _screen_node;

_screen_node screen_nodes[] = {
/*  0 */	{ 21,  1,  0,  3,  2,  3 },	// relays, db_step
/*  1 */	{  0,  2,  4,  9,  7,  9 },	// motor, pot, clock
/*  2 */	{  1,  3, 10, 13, 12, 13 },	// d1/d2 boards
/*  3 */	{  2,  4, 14, 17, 16, 17 },	// amp delay, sleep timer
/*  4 */	{  3,  5, 18, 22, 21, 22 },	// backlight min,max
/*  5 */	{  4,  6, 23, 25, 25, 25 },	// volume step, large
/*  6 */	{  5,  7, 26, 29, 28, 29 },	// minVol, maxVol
/*  7 */	{  6,  8, 30, 31, 31, 31 },	// userbanner1 (top)
/*  8 */	{  7,  9, 32, 33, 33, 33 },	// userbanner2 (bottom)
/*  9 */	{  8, 10, 36, 39, 38, 39 },	// port name1
/* 10 */	{  9, 11, 40, 43, 42, 43 },	// port name2
/* 11 */	{ 10, 12, 44, 47, 46, 47 },	// port name3
/* 12 */	{ 11, 13, 48, 51, 50, 51 },	// port name4
/* 13 */	{ 12, 14, 52, 55, 54, 55 },	// port name5
/* 14 */	{ 13, 15, 56, 59, 58, 59 },	// port name6
/* 15 */	{ 14, 16, 60, 63, 62, 63 },	// port name7
/* 16 */	{ 15, 17, 64, 67, 66, 67 },	// port name8
/* 17 */	{ 16, 18, 68, 73, 71, 73 },	// set clock (hh:mm:ss)
/* 18 */	{ 17, 19, 74, 78, 77, 78 },	// d1-1 H,L addresses
/* 19 */	{ 18, 20, 79, 83, 82, 83 },	// d1-2 H,L addresses
/* 20 */	{ 19, 21, 84, 88, 87, 88 },	// d2-1 H,L addresses
/* 21 */	{ 20,  0, 89, 93, 92, 93 },	// d2-2 H,L addresses
/* 22 */	{  0,  0,  0,  0,  0,  0 }	// sentinel
};


// menu fields
byte		current_screen_node;		// 0..n
int		current_menu_node;		// 0..n
byte		current_cursor_pos;		// 0..n
int		data_idx;
byte		data_type;

byte		blink_state;			// for cursor blinking
						// inside screen-edit windows
unsigned long	t_start;			// for cursor blinking
						// inside screen-edit windows
int		g_starting_data_node_idx;	// range of data nodes
						// (for circling around) 
int		g_ending_data_node_idx;
byte		capslock;

// when in menu edit mode and on a byte (int) variable, this saves the
// binary form of the var being edited
int		menu_edited_byte_var;
int		eeprom_index;
int		old_valuator = -1;
int		temp_valuator;
int		valuator = -1;


/*
 * flash string table, used for IR learning screen prompts.
 *  this table is very order-sensitive!
 *  more info, see other section: 'IFC = internal function codes'
 */
const char*	const fl_st_IR_learn[] PROGMEM = {
// note that the first 5 (important, frequently used) are cached
// in RAM at startup
/*  0 */	fl_st_up_fast,		// up-arrow
/*  1 */	fl_st_down_fast,	// down-arrow
/*  2 */	fl_st_up_slow,		// right-arrow
/*  3 */	fl_st_down_slow,	// left-arrow
/*  4 */	fl_st_mute,		// mute on/off key

/*  5 */	fl_st_up_alias,		// up-alias
/*  6 */	fl_st_down_alias,	// down-alias

/*  7 */	fl_st_power,		// power on/off key
/*  8 */	fl_st_menu,		// menu mode key
/*  9 */	fl_st_sleep,		// sleep on/off key

/* 10 */	fl_st_backlight,	// for backlight mode selection
/* 11 */	fl_st_display1,		// for display mode selection

/* 12 */	fl_st_one,		// for i/o selection
/* 13 */	fl_st_two,		// for i/o selection
/* 14 */	fl_st_three,		// for i/o selection
/* 15 */	fl_st_four,		// for i/o selection
/* 16 */	fl_st_five,		// for i/o selection
/* 17 */	fl_st_six,		// for i/o selection
/* 18 */	fl_st_seven,		// for i/o selection
/* 19 */	fl_st_eight,		// for i/o selection

/* 20 */	fl_st_nine,		// unused key
/* 21 */	fl_st_zero,		// unused key

/* 22 */	fl_st_multiout,		// multi-out on/off key

/* 23 */	fl_st_null		// end sentinel
};


#define IR_KEYPRESS_CACHE_SIZE		5	// 4 arrows and center button

unsigned long		ir_keypress_cache[IR_KEYPRESS_CACHE_SIZE];


/*
 * create an instance of the IR receiver class
 */
IRrecv			irrecv(IR_PIN);

extern unsigned long	key;		// IR key received


/*
 * create an instance of the lcd i2c 4bit class.
 *
 * this does a lot of stuff!  you get back a 'filled in' variable called 'lcd'
 * and the screen is initialized and ready for you to write to.
 */
LCDI2C4Bit	lcd = LCDI2C4Bit(LCD_MCP_DEV_ADDR, 2, 16, PWM_BACKLIGHT_PIN);
byte		lcd_in_use_flag;

#if 0		// not yet implemented
		// from EEPROM_DISPLAY_LCD_VFD
byte		display_type = DEFAULT_DISPLAY_TYPE;
		// from EEPROM_DISPLAY_SIZE
byte		display_size = DEFAULT_DISPLAY_SIZE;
#endif


/*
 * create an instance of the X10 (firecracker) class
 */
#ifdef USE_X10
X10		x10 = X10(X10_DTR_PIN, X10_RTS_PIN);
#endif


/***********************************
 *     start of main C code        *
 **********************************/

void
common_startup(byte admin_forced_flag)
{
	if (admin_forced_flag == 1)
		redraw_selector_string();

	redraw_volume_display(volume, admin_forced_flag);

	if (option_delta1_board_count == 0)
		return;	// if switch-only, everything has been displayed.

#ifdef USE_BIGFONTS
	/*
	 * sleep-mode icon, only in big-fonts mode
	 */
	if (big_mode == 1) {
		// sleep mode
		lcd.command(LCD_CURS_POS_L2_HOME + 15);

		if (sleep_mode == 1)
			lcd.write(0);   // timer icon
		else
			lcd.write(' '); // no timer icon
	}
#endif
}


void
power_on_off_countdown(byte up_down_flag)
{
	byte	i;

	lcd.clear();
	lcd.restore_backlight();

	if (up_down_flag == 1) {
		// Powering off: just display status and wait briefly
		lcd.send_string_P(fl_st_power, LCD_CURS_POS_L1_HOME+3);
		lcd.send_string_P(fl_st_status_off, 0);
		delay(800);
		return;
	} 
	else {
		// Powering on: display status and do power-on muting delay.
		lcd.send_string_P(fl_st_power, LCD_CURS_POS_L1_HOME+3);
		lcd.send_string_P(fl_st_status_on, 0);
		delay(800);

		lcd.clear();
		lcd.send_string_P(fl_st_amp_delay, LCD_CURS_POS_L1_HOME+3);

		for (i = EEPROM.read(EEPROM_POWERON_DELAY); i > 0; i--) {
			sprintf(string_buf, "%02d", i);
			// center of line2
			lcd.send_string(string_buf, LCD_CURS_POS_L2_HOME+7);

			// scan front button in case user did want to get
			// into config mode
			if (scan_front_button() == 1) {
				// user stays in this mode until
				// he's done, then control returns
				enter_config_mode();

				// do this just to re-read any changes
				// that happened during config_button time
				init_system();

				return;
			}

			delay(1000);  // wait 1 second
		}
	}
}


void
power_off_logic(void)
{
	power = POWER_OFF;
	//EEPROM.write(EEPROM_POWER, power);

	sleep_mode = 0;
	half_minutes = 0;
	last_sleep_time_display_minutes = 0;

#ifdef USE_MOTOR_POT
	digitalWrite(MOTOR_POT_ROTATE_CCW, LOW);	// stop turning left
	digitalWrite(MOTOR_POT_ROTATE_CW,  LOW);	// stop turning right
#endif

	// save the current volume level to EEPROM with forced admin; write to
	// eeprom even if the cache 'suggests' it's too early
	//cache_flush_save_current_vol_level(1);

#ifdef USE_D2_RELAYS
	// do a mute of some kind
	if (option_delta2_board_count == 1 || option_delta2_board_count == 2) {
		// 'lift' all relays (this mutes outputs, easily)
		update_delta2_state(0x00);
	}
	else
#endif
#ifdef USE_SPDIF
	if (option_delta2_board_count == 3) {
		// turn all the software-settable leds off
		pcf.write(delta_i2c_addr[I2C_SPDIF_ADDR_SLOT], B11110000);
	}
#endif

	if (option_delta1_board_count >= 1 && option_delta1_board_count <= 3) {
		// total hardware mute, no matter what.
		// admin-forced-flag = true
		send_vol_byte_to_engines(0x00, 1);
	}

	// display power-off status
	power_on_off_countdown(1);

	// now turn the blue-wire off
	turn_off_power_relay();

	lcd.cgram_load_normal_bargraph();
	lcd.clear();

	if (lcd.backlight_bright_mode != BACKLIGHT_MODE_FULL_DARK) {
		get_and_draw_logo_line(1);
#ifdef USE_DS1302_RTC
		if (option_ds1302_rtc_installed == RTC_UNINSTALLED) {
			get_and_draw_logo_line(2);
		}
#else
		get_and_draw_logo_line(2);
#endif
	}
}




// This routine assumes the LCD display is initialized and available
// for us to write status messages to.
void
power_on_logic(byte config_button_flag)
{
	lcd.clear();
	lcd.turn_display_on();
	lcd.clear();
	common_startup(1);

	// if power is ON, lcd must be visible ;)
	lcd.restore_backlight();

	turn_off_power_relay();

#ifdef USE_D2_RELAYS
	// do a mute of some kind
	if (option_delta2_board_count == 1 || option_delta2_board_count == 2) {
		// 'lift' all relays (this mutes outputs, easily)
		update_delta2_state(0x00);
	}
	else
#endif
	if (option_delta1_board_count >= 1 && option_delta1_board_count <= 3) {
		// total hardware mute, no matter what.
		// admin-forced-flag = true
		send_vol_byte_to_engines(0x00, 1);
	}

	// assert logic 5v line for power-on control
	turn_on_power_relay();

	// display power-on status and perform muting delay
	power_on_off_countdown(0);

#ifdef USE_ANALOG_POT
	// capture a value here so that we can define a 'starting value'
	// for our pot at power-on
	if (option_motor_pot_installed != 1 && option_pot_installed == 1) {
		last_seen_pot_value = read_analog_pot_with_smoothing(
			SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
		);	// to smooth it out
	}
#endif

	/*
	 * optional: display banner and check config button
	 */
	if (config_button_flag) {
		// Serial.println("Hello Banner.");

		signon_msg();

		// check if the user wanted to enter 'config mode'
		// (even an IR command can get you there, not just a
		// soft-reset button press)   
		if (check_config_button_with_timeout() == 1) {
			// user stays in this mode until done,
			// then control returns
			enter_config_mode();
		}
	}	// 'show banner and wait' flag

	init_system();
	lcd.clear();

	/*
	 * first-time power-on init of volume
	 */
  
// Mute 1st  
  volume = 000;
  if (option_delta1_board_count >= 1 && option_delta1_board_count <= 3) {
     // total hardware mute.
     send_vol_byte_to_engines(000, 1);
  }

// Resync the Knob 2nd
#ifdef USE_MOTOR_POT
	if (option_motor_pot_installed == 1) {
		pot_state = MOTOR_IN_MOTION;
		last_seen_pot_value = -1;
    delay(100);
    pot_state = MOTOR_SETTLED;
    delay(250);
    volume = last_seen_IR_vol_value;
    send_vol_byte_to_engines(last_seen_IR_vol_value, 1);
  }  
#endif
#ifdef USE_MOTOR_POT
  if (option_motor_pot_installed == 0) {
    last_seen_pot_value = -1;
    volume = 100;
    send_vol_byte_to_engines(100, 1);
  }  
#endif

// Manually Select #1st Input
  input_selector = 000;

}


void
resync_display_mode(void)
{
	display_mode = EEPROM.read(EEPROM_DISPLAY_MODE);

#ifdef USE_BIGFONTS
	if (display_mode == EEPROM_DISP_MODE_BIGFONTS) {
		big_mode = 1;
		display_mode_clock = 0;
		lcd.cgram_load_big_numeral_fonts();
	} 
	else
#endif
	if (display_mode == EEPROM_DISP_MODE_BARGRAPH) {
#ifdef USE_BIGFONTS
		big_mode = 0;
#endif
		display_mode_clock = 0;
		lcd.cgram_load_normal_bargraph();
	} 
	else if (display_mode == EEPROM_DISP_MODE_CLOCK ||
		 display_mode == EEPROM_DISP_MODE_SLEEP) {
#ifdef USE_BIGFONTS
		big_mode = 0;
#endif
		display_mode_clock = 1;
		lcd.cgram_load_normal_bargraph();
	} 
	else {	// default if no valid previous value was found
		display_mode = EEPROM_DISP_MODE_BARGRAPH;
#ifdef USE_BIGFONTS
		big_mode = 0;
#endif
		display_mode_clock = 0;
		lcd.cgram_load_normal_bargraph();
	}
}


/*
 * the arduino 'setup' routine.  mandatory and is run once (used to init stuff)
 */
void 
setup(void)
{
	byte	i2c_addr;
    
	// always start the wire library for i2C communication.
	// first (or very early)
	Wire.begin();

#if defined(USE_D1_RELAYS) || defined(USE_D2_RELAYS)
	// check if any relay (vol control or i/o) modules are installed
	if (option_delta1_board_count <= 2 && option_delta2_board_count <= 1) {
		// turn off the relays (safety)

		// pcf8574A version
		for (i2c_addr = B0111111; i2c_addr >= B0111000; i2c_addr--) {
			Wire.beginTransmission(i2c_addr);
			Wire.write(0);
			Wire.endTransmission();
		}

		// pcf8574 non-A version
		for (i2c_addr=B0100111; i2c_addr >= B0100000; i2c_addr--) {
			Wire.beginTransmission(i2c_addr);
			Wire.write(0);
			Wire.endTransmission();
		}

		/*
		 * delta1,2 relay boards
		 */

		pcf.write(delta_i2c_addr[4], 0x00);
		pcf.write(delta_i2c_addr[5], 0xff);
		pcf.write(delta_i2c_addr[6], 0x00);
		pcf.write(delta_i2c_addr[7], 0xff);
		delayMicroseconds(CLICK_DOWN_DELAY);	// 3 ms
  
		pcf.write(delta_i2c_addr[4], 0x00);
		pcf.write(delta_i2c_addr[5], 0x00);
		pcf.write(delta_i2c_addr[6], 0x00);
		pcf.write(delta_i2c_addr[7], 0x00);
		delayMicroseconds(CLICK_UP_DELAY);	// 3ms
	} // if at least 1 relay board is marked as 'installed'
#endif // USE_D1_RELAYS || USE_D2_RELAYS

	/*
	 * quickly make sure our power relay is OFF at our boot time
	 */
	pinMode(RELAY_POWER_PIN, OUTPUT);
	turn_off_power_relay();

	/*
	 * if this is the first time we are running, init some eeprom area
	 */
	if (EEPROM.read(EEPROM_MAGIC) != MY_MAGIC) {
		init_all_eeprom();

		// this signals that we're whole again ;)
		EEPROM.write(EEPROM_MAGIC, MY_MAGIC);
	} // eeprom was out of sync and we had to init it

	/*
	 * analog (maybe motor) pot init
	 */
#ifdef USE_ANALOG_POT
	pinMode(SENSED_ANALOG_POT_INPUT_PIN, INPUT);	// analog-in 1
#endif

#ifdef USE_MOTOR_POT
	pinMode(MOTOR_POT_ROTATE_CW,  OUTPUT);		// analog-2 used
							// as digital-15
	pinMode(MOTOR_POT_ROTATE_CCW, OUTPUT);		// analog-3 used
							// as digital-15

	digitalWrite(MOTOR_POT_ROTATE_CW, LOW);		// init to OFF
	digitalWrite(MOTOR_POT_ROTATE_CCW, LOW);	// init to OFF
#endif

	/*
	 * led13
	 */
	digitalWrite(LED13, LOW);			// init led13 to OFF

	/*
	 * reset state vars to known starting conditions
	 */
	init_system();

#ifdef USE_X10
	/*
	 * x10/firecracker init (not used in volumaster 1.0x)
	 */
	if (option_x10_firecracker == 1)
		x10.init();
#endif
   
	/*
	 * realtime clock chip init
	 */
#ifdef USE_DS1302_RTC
	rtc.init();
#endif

	/*
	 * if the pga vol control support is enabled
	 */
#ifdef USE_PGA_I2C
	pga23xx_init();
#endif

	/*
	 * LCD init (get this done early so you can display messages)
	 */
#if 0	// not yet implemented
	display_type = DISPLAY_TYPE_LCD;
#endif
	lcd.clear();
	lcd.SetInputKeysMask(LCD_MCP_INPUT_PINS_MASK);
	lcd.init();
	lcd.cgram_load_normal_bargraph();

	lcd.backlight_bright_mode = EEPROM.read(EEPROM_BACKLIGHT_MODE);
	lcd.backlight_min         = EEPROM.read(EEPROM_BACKLIGHT_MIN);
	lcd.backlight_max         = EEPROM.read(EEPROM_BACKLIGHT_MAX);

	/*
	 * restore last-used menu locations and display modes
	 */
	current_screen_node = EEPROM.read(EEPROM_MENU_PGNUM);
	current_menu_node   = EEPROM.read(EEPROM_MENU_NODENUM);
	current_cursor_pos  = 0;

	/*
	 * IR (infra red) receiver init
	 */
	irrecv.enableIRIn();		// Start the receiver

	/****************************
	 *  system ON (fresh boot)  *
	 ****************************/

	if (power == POWER_ON) {
		// power was marked in EEPROM as being 'on'
		power_on_logic(1);
		change_input_selector(input_selector);
		resync_display_mode();
		common_startup(1);
	}
	else {
		// power was supposed to be OFF
#ifdef USE_SPDIF
		if (option_delta2_board_count == 3) {
			// turn all the software-settable leds off
			pcf.write(delta_i2c_addr[I2C_SPDIF_ADDR_SLOT],
				  B11110000);
		}
#endif
		lcd.clear();

		if (lcd.backlight_bright_mode != BACKLIGHT_MODE_FULL_DARK) {
			lcd.turn_display_on();

			get_and_draw_logo_line(1);
#ifdef USE_DS1302_RTC
			if (option_ds1302_rtc_installed == RTC_UNINSTALLED)
#endif
				get_and_draw_logo_line(2);

			lcd.restore_backlight();
		}
	}
}


void
redraw_IR_prompt_string(int idx)
{
	display_progmem_string_to_lcd_P(&(fl_st_IR_learn[idx]),
					LCD_CURS_POS_L2_HOME+1);
}


/*
 * we get here if the user pressed the magic 'config button' in a short window
 * at bootup time
 */
void
enter_config_mode(void)
{
	int	i;
	int	idx;
	byte	cfg_finished;
	byte	blink_toggle;
	byte	blink_count;
	byte	skip_this_key;
	byte	skip_ir_learn;

	lcd.clear();
	lcd.set_backlight(255);	// force it to be the max

	// wait 3-5 seconds, total, just to give the user
	// a GOOD chance to remove finger from switch, so it won't cause
	// a false-positive
	for (i = 0; i < 4; i++) {
		lcd.send_string_P(fl_st_config_mode, LCD_CURS_POS_L1_HOME);
		if (i == 3)
			break;	// avoid clearing the display when we are done
		delay(300);
		lcd.clear();
		delay(70);
	}


	/*
	 * safety: before we reset anything, ask the user!
	 * we display a message and wait for user to press the button.
	 * if pressed, we will get a '1' return.
	 */

	/*
	 * does user want us to reset EEPROM to factory defaults?
	 */
	delay(1000);
	lcd.clear();
	lcd.send_string_P(fl_st_restore_def, LCD_CURS_POS_L1_HOME);

	if (check_config_button_with_timeout() == 1) {
		lcd.clear_line(LCD_LINE_TWO);	// bottom line
		lcd.send_string_P(fl_st_init_eeprom, LCD_CURS_POS_L2_HOME);
		init_all_eeprom();
	} 
	else {
		lcd.clear_line(LCD_LINE_TWO);	// bottom line
		lcd.send_string_P(fl_st_unchanged, LCD_CURS_POS_L2_HOME);
	}

#ifdef DEBUG_IR1
	/*
	 * does user want to run IR diag mode?
	 */

	delay(1000);
	lcd.clear();
	lcd.send_string_P(fl_st_IR_diag, LCD_CURS_POS_L1_HOME);
	lcd.write('?');  // make that mode a question

	if (check_config_button_with_timeout() == 1) {
		lcd.send_string_P(fl_st_IR_diag, LCD_CURS_POS_L1_HOME);
		lcd.write(':');  // make that mode a question
		delay(500);

		// stay in this mode until user presses button again
		while (scan_front_button() != 1) {
			key = get_IR_key();
			if (key != 0) {
				ir_key_dump(LCD_CURS_POS_L2_HOME);
				delay(150);
				lcd.clear_line(LCD_LINE_TWO);
			}
		}
	}

	// tell the user it's 'complete'
	lcd.send_string_P(fl_st_completed, LCD_CURS_POS_L2_HOME);
	delay(1000);	// wait about a second
#endif	// DEBUG_IR

	/*
	 * does user want us to re-learn IR codes?
	 */
	delay(1000);
	lcd.clear();
	lcd.send_string_P(fl_st_learn_ir, LCD_CURS_POS_L1_HOME);
	lcd.write('?');	// make that mode a question

	skip_ir_learn = 0;
	if (check_config_button_with_timeout() != 1) {
		lcd.clear_line(LCD_LINE_TWO);
		lcd.send_string_P(fl_st_unchanged, LCD_CURS_POS_L2_HOME);
		delay(1000);  // wait 1 second
		skip_ir_learn = 1;
	}

	if (!skip_ir_learn) {
		/*
		 * users said 'ok' and now we proceed to learn and store
		 * his IR codes, one by one.
		 */

		// we just consumed one key; 'start' to receive the next value
		irrecv.resume();

		lcd.clear();
		lcd.send_string_P(fl_st_learn_ir, LCD_CURS_POS_L1_HOME);
		lcd.write(':');		// make that mode a 'begin process'
		delay(2000);		// wait about a second

		// for each array item (0 .. MAX_FUNCTS-1) ask the user
		// to press a key, get it (or a timeout)
		idx = 0;
		cfg_finished = 0;

		while (!cfg_finished && (idx < MAX_FUNCTS)) {
			lcd.clear_line(LCD_LINE_TWO);

			// prompt the user for which key to press
			redraw_IR_prompt_string(idx);
	    
			blink_toggle = 1;
			blink_count = 0;
			skip_this_key = 0;

			/*
			 * non-blocking poll for a keypress
			 */
			while (!cfg_finished && !skip_this_key) {
				// quick one-shot grab for a key.
				// non-blocking.  returns 0 if no key seen yet.
				key = get_IR_key();
				if (key != 0) {
					skip_this_key = 0;

					// exit this blink-loop
					// when we found a key
					break;
				}

				// we just consumed one key; 'start' to
				// receive the next value
				irrecv.resume();

				if (blink_toggle == 1) {
					blink_toggle = 0;
					// erase the line
					lcd.clear_line(LCD_LINE_TWO);
					// let the eye see it for a bit
					delay(150);
				} 
				else {
					blink_toggle = 1;
					++blink_count;
					redraw_IR_prompt_string(idx);
					// let the eye see it for a bit longer
					delay(300);
				}

				// does the user want us to skip this key?
				// if so, we do NOT write any value into
				// this index and just move onto the next.
				if (scan_front_button() == 1) {
					skip_this_key = 1;
					lcd.clear_line(LCD_LINE_TWO);

					// acknowledge to the user
					lcd.send_string_P(
						fl_st_keyskipped,
						LCD_CURS_POS_L2_HOME+1
					);

					delay(500);  // wait half a second
					break;
				}
				else if (blink_count >= 40) {
					// check if we should exit
					// (user got into this mode but had
					// 2nd thoughts).  a long timeout
					// means 'abort'.

					// the user didn't want us to go on,
					// so we bail out.
					cfg_finished = 1;

					// back to main 'everyday use' mode
					toplevel_mode = TOPLEVEL_MODE_NORMAL;

					lcd.clear();
					// tell the user it's 'complete'
					lcd.send_string_P(
						fl_st_completed,
						LCD_CURS_POS_L2_HOME
					);

					delay(1000);  // wait 1 second
					return;
				}
			}	// while

			/*
			 * if we got here, a non-blank IR keypress was detected
			 * or the user skipped this code.
			 */
			if (!skip_this_key && !cfg_finished) {

#if 0	// not yet implemented
				// search the list of known keys
				// to make sure this isn't a dupe or mistake
				// [tbd]
				// search_eeprom_for_IR_code();
#endif

				/*
				 * accept this keypress and save it in
				 * EEPROM (later: bank-selecting if complete
				 * run detected)
				 */
#ifdef DEBUG_IR1
				// for debug
				ir_key_dump(LCD_CURS_POS_L1_HOME);
#endif

				// this signals to the user that we got his key
				lcd.send_string("*", LCD_CURS_POS_L2_HOME);
				redraw_IR_prompt_string(idx);

				EEwrite_long(EEPROM_IR_LEARNED_BASE_BANK + (idx * sizeof(long)), key);
			}

			idx++;			// point to the next IR key
						// to learn
			last_key_value = 0;	// clear out our key memory
			delay(1000);		// debounce a little more
			irrecv.resume();	// we just consumed one key,
						// start to receive next
		}	// while
	}	// if !skip_ir_learn

	/*
	 * (re)get the IR keycodes that we previously learned
	 */
	// back to main 'everyday use' mode
	toplevel_mode = TOPLEVEL_MODE_NORMAL;
	read_IR_learned_keys_from_eeprom();

	lcd.clear();
	lcd.restore_backlight();
	lcd.send_string_P(fl_st_completed, LCD_CURS_POS_L1_HOME);

	delay(500);
	lcd.clear();
}


void
processing_while_system_is_off(void)
{
#ifdef USE_DS1302_RTC
	if (lcd.backlight_bright_mode != BACKLIGHT_MODE_FULL_DARK) {
		if (option_ds1302_rtc_installed == RTC_INSTALLED) {
			// 2nd line, 5rd char over from left
			lcd.cursorTo(1, 4);

			// admin=no, second_hand=yes
			redraw_clock(0, 1);
		}
	}
#endif

	// do any valid power-off-allowed modes, here

	// scan for IR and front-panel power-on sequences (that's all we care
	// about if we are in the power=off state)
	handle_IR_keys_normal_mode();

	/*
	 * timeout the lcd backlight if we are in the right mode and it's been
	 * 'too long' since the last keypress
	 */
	lcd.handle_backlight_auto();
}


/***********************************************************************
 * loop() is a required standard arduino thing.  you have to provide
 * a setup() and a loop().  setup() is used at init-time
 * and loop() is called in an endless loop. (ie, if loop exits, it
 * gets called again.
 **********************************************************************/

void 
loop(void)
{
	/******************************************
	 * serial (rs232) keyscan routines
	 *****************************************/
#ifdef USE_SERIAL_UART
	handle_any_serial_TTY_io();
#endif

	// If power is off, we do only minimal processing
	if (power == POWER_OFF) {
		processing_while_system_is_off();
		return;
	}

	// main 'everyday use' mode

	/*
	 * menu mode
	 */
	if (toplevel_mode == TOPLEVEL_MODE_MENU) {
		handle_IR_keys_menu_mode();
		return;
	}

	/*
	 * power is NOT off; so we have to actually scan 
	 */

	/*
	 * sleep timer tick routines and 
	 * RTC clock display feature
	 */
	if (sleep_mode == 1) {
		handle_sleep_mode_timeslice();
	}

	/*
	 * update sleep time or clock display?
	 */
	if (mute != 1) {
		// MUTE always overrides clock and sleep timer display
		if (display_mode == EEPROM_DISP_MODE_SLEEP)
		update_sleep_display_time(0);
	} 
#ifdef USE_DS1302_RTC
	else if (display_mode == EEPROM_DISP_MODE_CLOCK) {
		if (lcd.backlight_bright_mode != BACKLIGHT_MODE_FULL_DARK) {
			update_alternate_clock_display(0);
		}
	}
#endif

	/*********************************************************************
	 * this routine has to be called semi-frequently.  it flushes the
	 * cached volume level to EEPROM; but only if it's been longer than
	 * 'X' seconds since the last write of 'volume' to the proper input
	 * port memory location
	 *********************************************************************/

	//cache_flush_save_current_vol_level(0);

	/*********************************************************************
	 * motor-pot (move the motor via the h-bridge chip CW or CCW)
	 *********************************************************************/

#ifdef USE_ANALOG_POT
	// read the analog pot, first
	if (option_pot_installed == 1)
		analog_sensed_pot_logic();
#endif

#ifdef USE_MOTOR_POT
	// always check the motor logic 2nd
	if (option_motor_pot_installed == 1)
		motor_pot_logic();
#endif

	/******************************************
	 * IR keyscan and case-statement routines
	 *****************************************/

	handle_IR_keys_normal_mode();


	/***********************************************************
	 * timeout the lcd backlight if we are in the right mode
	 * and it's been 'too long' since the last keypress
	 ***********************************************************/

	lcd.handle_backlight_auto();
} 


// use this for multi-mode output style, only
void
format_output_port_state_char(byte port_num_mask, char *dest_string_buf)
{
	byte	port_num;
	byte	mask;
	byte	my_port_state;
	byte	idx = 0;

	for (port_num = 0; port_num < MAX_IOPORTS; port_num++) {
		mask = (1 << (7 - port_num));

		my_port_state = get_port_state(port_num);

		if (my_port_state == PORT_AS_INPUT) {
			// we think it's an input port
			if (port_num == input_selector)
				dest_string_buf[idx++] = 'I';
			else
				dest_string_buf[idx++] = '-';
		}
		else if (my_port_state == PORT_AS_DISABLED) {
			// n/a shows as a dash char
			dest_string_buf[idx++] = '-';
		}
		else if ((mask & port_num_mask) != 0) {
			// this output IS selected
			dest_string_buf[idx++] = ('1' + port_num);
		}
		else {
			// this output is not selected
			dest_string_buf[idx++] = '-';
		}
	}	// for each bit in the port byte

	dest_string_buf[8] = '\0';	// terminate the string
}


// formats to temp string space, then displays to LCD
void
print_output_port_state_char(byte port_num)
{
	char dest_string_buf[9];

	format_output_port_state_char(port_num, dest_string_buf);
	lcd.send_string(dest_string_buf, 0);
}


/*
 * this routine repaints just the lcd section with the input and/or
 * output selector names
 */
void 
redraw_selector_string(void)
{
#ifdef USE_BIGFONTS
	if (big_mode == 1)
		return;		// no selector strings in big font mode!
#endif

	// clear top line
	lcd.clear_line(LCD_LINE_ONE);

	// we don't print input or output port names if there is
	// no d2 installed
	if (option_delta2_board_count == 0)
		return;

	// input port name
	if (get_port_state(input_selector) == PORT_AS_INPUT) {
		// copies EEPROM field into string_buf[]
		eeprom_read_port_name(input_selector);
		string_buf[LEN_PORTNAME_STRING] = '\0';	// safety
		lcd.send_string(string_buf, LCD_CURS_POS_L1_HOME);
	}

	// output port name
	output_selector = EEPROM.read(EEPROM_OUTPUT_SEL);
	output_selector_mask = EEPROM.read(EEPROM_OUTPUT_SEL_MASK);

	if (get_port_state(output_selector) == PORT_AS_OUTPUT) {
		if (output_mode_radio_or_toggle == OUTPUT_MODE_RADIO) {

			// copies EEPROM field into string_buf[]
			eeprom_read_port_name(output_selector);
			string_buf[LEN_PORTNAME_STRING] = '\0';	// safety

			// set cursor
			lcd.cursorTo(0, STRING_BUF_MAXLEN-1-8);
			// the 2nd 8char string field, top line/right
			lcd.send_string(string_buf, 0);
		}
		else {
			// set cursor
			lcd.cursorTo(0, STRING_BUF_MAXLEN-1-8);
			// print all 8 chars as - or  or number of port
			print_output_port_state_char(output_selector_mask);
		}
	}
}


/*
 * what's with this half-minutes stuff?  well, the millis() counter rolls
 * over pretty often, so we watch the half-minute mark and count those
 * and then divide those by 2 to get 'real minutes' when we have to do
 * compares ;)
 */
void
update_sleep_display_time(byte admin_flag)
{
	int	minutes;
	byte	ms, ls;

#ifdef USE_BIGFONTS
	if (big_mode == 1)
		return;		// no count-down on bigfonts mode
#endif

	// only do lcd writing if there is a change from the
	// last remaining_minutes value
	if (half_minutes != last_sleep_time_display_minutes ||
	    admin_flag == 1) {
		// save for next compare
		last_sleep_time_display_minutes = half_minutes;

		lcd_clear_8_chars(LCD_MAIN_SLEEP_COUNTDOWN_LOC);
		lcd.command(LCD_MAIN_SLEEP_COUNTDOWN_LOC);

		if (sleep_mode == 1) {
		      minutes = EEPROM.read(EEPROM_SLEEP_INTERVAL) - (int)(half_minutes/2);
		      bin2ascii(minutes, &ms, &ls);
		      lcd.write('S');
		      lcd.write(ms); 
		      lcd.write(ls);
		}
		else {
#ifdef ALWAYS_SHOW_SLEEP
		      lcd.write('S');
		      lcd.write('-'); 
		      lcd.write('-'); 
#endif
		}
	}
}



void
update_alternate_clock_display(byte admin_flag)
{
#ifdef USE_DS1302_RTC
	if (option_ds1302_rtc_installed == RTC_INSTALLED) {
		// try to avoid calling the RTC too often.
		// use millis() to see if we should bother the clock.
		if (admin_flag == 1 ||
		    (abs(millis() - last_clock_update) > 2000)) {
			last_clock_update = millis();
			rtc.GetTime();

			// keep the screen updates down!
			if (rtc.Mins != last_mins || admin_flag == 1) {
				// clear the quadrant
				lcd_clear_8_chars(LCD_MAIN_CLOCK_LOC);
				lcd.command(LCD_MAIN_CLOCK_LOC);
				ShowTime(0 /*second_hand_shown*/);

				// only re-display clock if the seconds
				// have changed OR if admin-forced was 'true'
				last_mins = rtc.Mins;  // save for next loop
				last_secs = rtc.Secs;
				last_hrs  = rtc.Hrs;
			}	// if it was time for a screen update
		}	// if millis() was big enough
	}	// RTC_INSTALLED
#endif
}


/*
 * routine that gets called in the main polling loop to count-down
 * the sleep time and take action if it's 'time'
 */
void
handle_sleep_mode_timeslice(void)
{
	unsigned long	now = millis();

	// 60 seconds expired?
	if (abs(now - sleep_start_time) > (30*1000)) {
		// see previous rant about half-minutes and millis() rollovers
		half_minutes++;
		sleep_start_time = millis();	// get a new snapshot
	}

	/*
	 * is it shutdown time yet?
	 */
	// 60 minutes by default
	if (half_minutes >= (2 * EEPROM.read(EEPROM_SLEEP_INTERVAL))) {
		lcd.clear();
		lcd.send_string_P(fl_st_goodnight, LCD_CURS_POS_L1_HOME);
		delay(3000);

		power_off_logic();

		toplevel_mode = TOPLEVEL_MODE_NORMAL;
	}
}


void
toggle_mute(void)
{
	if (option_delta1_board_count == 0)
		return;

	lcd.restore_backlight();

	if (mute == 0) {	// mute==0 when mute feature is OFF 
		if (vol_span == 0) {
			// Don't mute if min_vol == max_vol
			return;
		}

#ifdef USE_MOTOR_POT
		// as a precaution, stop any motors (if any)
		digitalWrite(MOTOR_POT_ROTATE_CCW, LOW);  // stop turning left
		digitalWrite(MOTOR_POT_ROTATE_CW,  LOW);  // stop turning right
#endif

		update_volume(min_vol, 1);
		mute = 1;  // toggle its value

		redraw_volume_display(volume, 1);  // draw the '--' chars
	} 
	else {	// UNMUTE
		mute = 0;  // toggle its value
		update_volume(volume, 1);
	}
}


// old_s and new_s are string buffers, 8-char max
void
show_port_change_event(char *old_s, char *new_s)
{
	lcd.restore_backlight();
	lcd.clear();

	lcd.send_string("Old:", LCD_CURS_POS_L1_HOME);
	lcd.send_string(old_s, LCD_CURS_POS_L1_HOME+8);

	lcd.send_string("New:", LCD_CURS_POS_L2_HOME);
	lcd.send_string(new_s, LCD_CURS_POS_L2_HOME+8);
}


// handle port change
void
port_common(byte port_num)
{
	byte	my_port_state;
#ifdef USE_BIGFONTS
	char	old_s[9];
	char	new_s[9];
#endif

	if (power == POWER_OFF)
		return;   // do nothing if power is not on

	lcd.restore_backlight();

	if (option_delta2_board_count == 0)
		return;

#ifdef USE_BIGFONTS
	memset(old_s, ' ', 8);
	old_s[8] = '\0';

	memset(new_s, ' ', 8);
	new_s[8] = '\0';
#endif

	my_port_state = get_port_state(port_num);

	if (my_port_state == PORT_AS_OUTPUT) {
		// save this for our display, later
		old_port = output_selector;

		if (output_mode_radio_or_toggle == OUTPUT_MODE_RADIO) {
			// radio mode
			if (output_selector == port_num)
				// user pressed a button that would
				// cause no change
				return;

#ifdef USE_BIGFONTS
			if (big_mode == 1) {
				// save the 'old' value as a string
				old_port = output_selector;
				eeprom_read_port_name(old_port);
				strncpy(old_s, string_buf, 8);
			}
#endif

			// do the switch with actual hardware
			output_port_common(port_num);

#ifdef USE_BIGFONTS
			if (big_mode == 1) {
				// save the 'new' value as a string
				eeprom_read_port_name(port_num);
				strncpy(new_s, string_buf, 8);
      
				// display the change event to the lcd
				show_port_change_event(old_s, new_s);

				// show the old/new, delay, and then
				// clear/redraw main
				delay(1000);
				lcd.clear();
			}
#endif

			common_startup(1);
		}
		else {
			// toggle mode

#ifdef USE_BIGFONTS
			if (big_mode == 1) {
				// save the 'old' value as a string
				old_port_mask = output_selector_mask;
				// save this for our display, later
				format_output_port_state_char(
					old_port_mask, old_s
				);
			}
#endif

			// do the switch with actual hardware
			output_port_common(port_num);

#ifdef USE_BIGFONTS
			if (big_mode == 1) {
				// save the 'new' value as a string
				format_output_port_state_char
					(output_selector_mask, new_s
				);

				// display the change event to the lcd
				show_port_change_event(old_s, new_s);

				delay(1000);
				lcd.clear();
			}
#endif
			common_startup(1);
		}
	}
	else if (my_port_state == PORT_AS_INPUT) {
		if (input_selector == port_num)
			// user pressed a button that would cause no change
			return;

#ifdef USE_BIGFONTS
		if (big_mode == 1) {
			// save the 'old' value as a string
			old_port = input_selector;
			eeprom_read_port_name(old_port);
			strncpy(old_s, string_buf, 8);

			// save the 'new' value as a string
			eeprom_read_port_name(port_num);
			strncpy(new_s, string_buf, 8);

			// display the change event to the lcd
			show_port_change_event(old_s, new_s);
		}
#endif

		// do the switch in actual hardware
		input_port_common(port_num);

#ifdef USE_BIGFONTS
		if (big_mode == 1) {
			// show the old/new, delay, and then clear/redraw main
			delay(1000);
			lcd.clear();
		}
#endif
		common_startup(1);
	}

	delay(400);	// general debounce
}


// note, port_num for input ports range is [0..MAX_IOPORT-1]
void
input_port_common(byte port_num)
{
#ifdef APP_BLINK_ON_LED13
	blink_led13(1);
#endif

	/*
	 * save the old volume to EEPROM in it's proper slot
	 */

	// change inputs
	// this modifies the global 'input_selector'
	change_input_selector(port_num);
}


// note, port_num for output ports range is [0..MAX_IOPORT-17]
void
output_port_common(byte port_num)
{
	byte	portnum_mask;

#ifdef APP_BLINK_ON_LED13
	blink_led13(1);
#endif

	// change setting
	if (output_mode_radio_or_toggle == OUTPUT_MODE_RADIO) {
		// if NOT in multi-mode, we save the selector as our port_num
		output_selector = port_num;	// take on the new number
		// we count ports from the left of the byte,
		// so 'human' port 1 == bit7
		output_selector_mask = (1 << (7 - port_num));

		// save for when we have to go back to radio-button mode
		last_saved_out_sel = output_selector;
		last_saved_out_sel_mask = output_selector_mask;
	} 
	else {
		// toggle-button style: toggle our state and leave
		// the others untouched
		portnum_mask = (1 << (7 - port_num));

		// if in mult-mode, we NEVER save
		// output_selector, only its mask
		if (output_selector_mask & portnum_mask) {
			// clear our bit  (note, the (byte)
			// is NEEDED due to how the compiler works)
			output_selector_mask &= ((byte)~portnum_mask);
		} 
		else {
			// set our bit
			output_selector_mask |= ((byte)portnum_mask);
		}
	}

	/*
	 * save the new values to EEPROM and also make the i/o board
	 * do its thing
	 */
	change_output_selector(output_selector, output_selector_mask);
}


void
notify_user_1(const char* PROGMEM message, int screen_pos)
{
	lcd.clear();
	lcd.send_string_P(message, screen_pos);
}


void
notify_user_2(const char* PROGMEM message, int screen_pos)
{
	lcd.send_string_P(message, screen_pos);
}


void
handle_IR_keys_normal_mode(void)
{
	int	i;
	byte	let_go;

	// one-shot check if the front button was pressed  

	if (power == POWER_ON) {
		if (scan_front_button()) {
			// check if the button is pressed/held for more
			// than 2 seconds; if so, then turn power off.
			let_go = 0;

			for (i = 0; i < 20; i++) {
				if (!scan_front_button()) {
					let_go = 1;
					// user let go, lets see if he held
					// it down long enough to mean
					// 'power-off'
					break;
				}
				delay(100);
			}

			/*
			 * turn power off if the user really asked us to
			 */
       
			if (!let_go) {	// power-off request!
				power_off_logic();
				delay(1000);	// debounce

				// we just consumed one key;
				// 'start' to receive next
				irrecv.resume();

				return;
			} // power-off request due to LONG PRESS on cfg button
			/*
			 * not a power-off request, so restore backlight
			 * since we were 'woken up'
			 */
			lcd.restore_backlight();

			// option choice: if user wanted the 'config button'
			// to be a mute, do this now
			toggle_mute();
			delay(250); // Debounce switch

			// we just consumed one key; 'start' to receive next
			irrecv.resume();

			return;
		}	// scan front button

		/************************************************
		 *   front panel config POWER BUTTON feature
		 ************************************************/

		// power was OFF
		// double duty: when power is off, use this as a
		// power-on button
	}
	else {
		if (scan_front_button()) {
			delay(150);   // debounce

			power = POWER_ON;		// we're now on
			//EEPROM.write(EEPROM_POWER, power);
   
			/*
			 * now we start the remote amp turn-on delay (if any)
			 */
			power_on_logic(1);  // 1 = 'show banner & wait'
			change_input_selector(input_selector);
			resync_display_mode();
			common_startup(1);

			irrecv.resume();

			return;
		}	// scan front button
	}	// power was OFF

	/*
	 * we got a valid IR start pulse! fetch the keycode, now.
	 */
	key = get_IR_key();
	if (key == 0) {
		return;		// try again to sync up on an IR start-pulse
	}
	/*
	 * volume UP, slow (via cache search)
	 */
	else if (key == ir_keypress_cache[IFC_VOL_UP_SLOW] ||
		 search_eeprom_for_IR_code() == IFC_VOL_UP_ALIAS) {
		if (power == POWER_OFF)
			return;	// power was in the 'off' or 'standby' state

#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		// Serial.println("up");

		vol_change_relative(VC_UP, VC_SLOW);
		delay(VOL_DELAY_SHORT);	// debounce
	}
	/*
	 * volume DOWN, slow (via cache search)
	 */
	else if (key == ir_keypress_cache[IFC_VOL_DOWN_SLOW] ||
		 search_eeprom_for_IR_code() == IFC_VOL_DOWN_ALIAS) {
		if (power == POWER_OFF)
			return;	// power was in the 'off' or 'standby' state
      
#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		// Serial.println("down");

		vol_change_relative(VC_DOWN, VC_SLOW);
		delay(VOL_DELAY_SHORT);  // debounce
	}
	/*
	 * volume UP, fast (via cache search)
	 */
	else if (key == ir_keypress_cache[IFC_VOL_UP_FAST]) {
		if (power == POWER_OFF)
			return;	// power was in the 'off' or 'standby' state
    
#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		// Serial.println("UP");

		vol_change_relative(VC_UP, VC_FAST);
		delay(VOL_DELAY_SHORT);  // debounce
	}
	/*
	 * volume DOWN, fast (via cache search)
	 */
	else if (key == ir_keypress_cache[IFC_VOL_DOWN_FAST]) {
		if (power == POWER_OFF)
			return;	// power was in the 'off' or 'standby' state
    
#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		// Serial.println("DOWN");

		vol_change_relative(VC_DOWN, VC_FAST);
		delay(VOL_DELAY_SHORT);  // debounce
	}
	/*
	 * mute button
	 */
	else if (key == ir_keypress_cache[IFC_MUTE_ONOFF]) {
		if (power == POWER_OFF)
			return;	// power was in the 'off' or 'standby' state

		lcd.restore_backlight();

#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		toggle_mute();

		delay(400);
	}

	/************ end of volume up/down section ************/

	/*
	 * input selectors (restore last-used vol setting for THAT port)
	 */
	else if (search_eeprom_for_IR_code() == IFC_KEYPAD1) {
		port_common(0);
	}
	else if (search_eeprom_for_IR_code() == IFC_KEYPAD2) {
		port_common(1);
	}
	else if (search_eeprom_for_IR_code() == IFC_KEYPAD3) {
		port_common(2);
	}
	else if (search_eeprom_for_IR_code() == IFC_KEYPAD4) {
		port_common(3);
	}
	else if (search_eeprom_for_IR_code() == IFC_KEYPAD5) {
		port_common(4);
	}
	else if (search_eeprom_for_IR_code() == IFC_KEYPAD6) {
		port_common(5);
	}
	else if (search_eeprom_for_IR_code() == IFC_KEYPAD7) {
		port_common(6);
	}
	else if (search_eeprom_for_IR_code() == IFC_KEYPAD8) {
		port_common(7);
	}  // ports 0..MAX_IOPORTS-1
	/*
	 * menu button
	 */
	else if (search_eeprom_for_IR_code() == IFC_MENU) {
		if (power == POWER_OFF)
			return;	// not allowed if power is off

#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		// always do this, no matter what state the
		// power switch was in)
		lcd.restore_backlight();

		toplevel_mode = TOPLEVEL_MODE_MENU;

#ifdef USE_MOTOR_POT
		// safety: stop any motor if it was moving at the time
		digitalWrite(MOTOR_POT_ROTATE_CCW, LOW);  // stop turning left
		digitalWrite(MOTOR_POT_ROTATE_CW,  LOW);  // stop turning right

		// wait for the motor to settle; this will stop false-triggers
		// right after we get into menu mode
		delay(750);
#endif

		// forced admin; write to eeprom even if the cache
		// 'suggests' it's too early
		//cache_flush_save_current_vol_level(1);
		delay(100);

		// kill our 'typeahead buffer' on IR (prevent mistaken IR keys)
		irrecv.resume();

#ifdef USE_ANALOG_POT
		// save a snapshot of the current pot value so that when we
		// enter a field, we won't suddenly think a value changed on us
		if (option_pot_installed == 1) {
			last_seen_pot_value = read_analog_pot_with_smoothing(
				SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
			); 
		}
#endif

		// startup our 'app':
		lcd.clear();
		// draw the menu 'page' (or screen); using the last one
		// from eeprom or actual use
		menu_draw_screen(current_screen_node);
	}	// menu button

	/*********************
	 *   IR power button
	 *********************/
	else if (search_eeprom_for_IR_code() == IFC_POWER_ONOFF) {
		lcd.restore_backlight();

#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		if (power == POWER_OFF) {	// power was in the 'off' state
			power = POWER_ON;	// we're now on
			//EEPROM.write(EEPROM_POWER, power);
			power_on_logic(0);	// 0 = no banner, quick startup
			change_input_selector(input_selector);
			resync_display_mode();
			common_startup(1);
		}
		else {
			power = POWER_OFF;	// we're now off
			//EEPROM.write(EEPROM_POWER, power);
			power_off_logic();
		}

		delay(400);
	}
	/*
	 * output toggle/radio: (RADIO button style or TOGGLE button style)
	 */
	else if (search_eeprom_for_IR_code() == IFC_MULTI_OUT) {
		if (power == POWER_OFF)
			return;	// not allowed if power is off

		lcd.restore_backlight();

#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		/*
		 * cycle around output toggle vs radio button modes
		 */
		cycle_between_output_toggle_radio_modes();

	}
	/*
	 * sleep mode toggle
	 */
	else if (search_eeprom_for_IR_code() == IFC_SLEEP_ONOFF) {
		if (power == POWER_OFF)
			return;	// power was in the 'off' or 'standby' state

		lcd.restore_backlight();

#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		/*
		 * cycle around sleep on/off modes
		 */
		cycle_between_sleep_modes();
	}

	/*
	 * DISPLAY mode toggle
	 */
	else if (search_eeprom_for_IR_code() == IFC_DISPLAY_MODE) {
		if (power == POWER_OFF)
			return;	// power was in the 'off' or 'standby' state

		lcd.restore_backlight();

#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		/*
		 * cycle around the 3 modes:
		 * (0)normal, (1)bigfont, (2)sleep-normal, (3)clock-normal
		 */
		cycle_between_display_modes();
	}

	/*
	 * cycle thru the backlight display modes
	 */
	else if (search_eeprom_for_IR_code() == IFC_BACKLIGHT) {
		// This one is allowed in powered off state
		lcd.restore_backlight();

#ifdef APP_BLINK_ON_LED13
		blink_led13(1);
#endif

		/*
		 * auto backlight, full bright, full dark, etc
		 */
		cycle_between_backlight_modes();
	}

/*****************************************************************************
 * common exit: everyone goes here to have their LED turned off and have IR  *
 * rescan itself                                                             *
 *****************************************************************************/

#ifdef APP_BLINK_ON_LED13
	blink_led13(0);
#endif

	irrecv.resume();	// we just consumed one key; 'start'
				// to receive next
}


/****************************
 *       cycle around ...   *
 ****************************/


void
cycle_between_sleep_modes(void)
{
	notify_user_1(fl_st_sleep, LCD_CURS_POS_L1_HOME);

	if (sleep_mode == 1) {
		sleep_mode = 0;
		half_minutes = 0;
		sleep_start_time = 0;
		notify_user_2(fl_st_status_off, 0);
	} 
	else {
		sleep_mode = 1;
		half_minutes = 0;
		// trigger an initial draw
		last_sleep_time_display_minutes = -1;
		// start counting from NOW
		sleep_start_time = millis();
		notify_user_2(fl_st_status_on, 0);
	}

	delay(1000);	// delay for 'notify_user_2()'

#ifdef USE_BIGFONTS
	if (big_mode == 1)
		lcd.clear();
#endif

	common_startup(1);
}


void
cycle_between_backlight_modes(void)
{
	/*
	 * full_dark->full_bright
	 */
	if (lcd.backlight_bright_mode == BACKLIGHT_MODE_FULL_DARK) {
		// flip it
		lcd.backlight_bright_mode = BACKLIGHT_MODE_FULL_BRIGHT;
		// save value to EEPROM
		//EEPROM.write(EEPROM_BACKLIGHT_MODE, lcd.backlight_bright_mode);

		notify_user_1(fl_st_backlight, LCD_CURS_POS_L1_HOME);
		notify_user_2(fl_st_status_on, 0);

		// show the new status to the user and wait before
		// we clear the message away
		delay(700);
  
#ifdef USE_SPDIF
		if (option_delta2_board_count == 3) {   // s-addr type
			// lower part of byte is the address, in binary.
			// upper part of byte is a mask used to light
			// 'courtesy leds' ;)
			byte	inverted_shifted_mask =
					 ~(1 << (input_selector+4));
			// only keep the top 4 bits
			inverted_shifted_mask &= B11110000;
			pcf.write(delta_i2c_addr[I2C_SPDIF_ADDR_SLOT],
				  inverted_shifted_mask | (input_selector+0));
		}
#endif

		if (power == POWER_OFF) {
			// powered off: display the banners
			lcd.clear();
			get_and_draw_logo_line(1);
#ifdef USE_DS1302_RTC
			if (option_ds1302_rtc_installed == RTC_UNINSTALLED)
				get_and_draw_logo_line(2);
#else
			get_and_draw_logo_line(2);
#endif
		} 
		else {
#ifdef USE_BIGFONTS
			if (big_mode == 1)
				lcd.clear();
#endif

			common_startup(1);
		}
	}	// full_dark->full_bright
	/*
	 * auto_dim->full_dark
	 */
	else if (lcd.backlight_bright_mode == BACKLIGHT_MODE_AUTO_DIM) {
		// flip it
		lcd.backlight_bright_mode = BACKLIGHT_MODE_FULL_DARK;
		// save value to EEPROM
		//EEPROM.write(EEPROM_BACKLIGHT_MODE, lcd.backlight_bright_mode);

		// show the new status to the user
		notify_user_1(fl_st_backlight, LCD_CURS_POS_L1_HOME);
		notify_user_2(fl_st_status_off, 0);
		delay(700);

#ifdef USE_SPDIF
		if (option_delta2_board_count == 3) {	// s-addr type
			// force the upper bits to be all 1
			// (which turns OFF our leds!)
			pcf.write(delta_i2c_addr[I2C_SPDIF_ADDR_SLOT],
				  B11110000 | (input_selector+0));
		}
#endif

		lcd.clear();

		if (power == POWER_ON) {
			resync_display_mode();
			common_startup(1);
		}

		// fade backlight to full dark.
		// this also sets 'backlight_state BACKLIGHT_IS_OFF'
		lcd.fade_backlight_complete_off();
	}
	/*
	 * full_bright->auto_dim
	 */
	else if (lcd.backlight_bright_mode == BACKLIGHT_MODE_FULL_BRIGHT) {
		// flip it
		lcd.backlight_bright_mode = BACKLIGHT_MODE_AUTO_DIM;
		// save value to EEPROM
		//EEPROM.write(EEPROM_BACKLIGHT_MODE, lcd.backlight_bright_mode);

		// show the new status to the user
		notify_user_1(fl_st_backlight, LCD_CURS_POS_L1_HOME);
		notify_user_2(fl_st_status_auto, 0);
		delay(700);

		if (power == POWER_OFF) {
			lcd.clear();
			// powered off: display the banners
			get_and_draw_logo_line(1);
#ifdef USE_DS1302_RTC
			if (option_ds1302_rtc_installed == RTC_UNINSTALLED)
				get_and_draw_logo_line(2);
#else
			get_and_draw_logo_line(2);
#endif
		}
		else {
#ifdef USE_BIGFONTS
			if (big_mode == 1)
				lcd.clear();
#endif

			common_startup(1);
		}
	}
}


void
cycle_between_display_modes(void)
{
	if (display_mode == EEPROM_DISP_MODE_BARGRAPH) {
#ifdef USE_BIGFONTS
		// jump over bigfonts mode if you are in switch-only
		// (no vol engine) config
		if (option_delta1_board_count != 0) {
			display_mode = EEPROM_DISP_MODE_BIGFONTS;
			EEPROM.write(EEPROM_DISPLAY_MODE, display_mode);
			big_mode = 1;
			display_mode_clock = 0;
			lcd.clear();
			lcd.cgram_load_big_numeral_fonts();
			lcd.clear();
			// 2 clear's to get rid of any screen garbage

			common_startup(1);
		} 
		else
		{
			// switch-only: go from bargraph to sleep-clock mode
			display_mode = EEPROM_DISP_MODE_SLEEP;
			EEPROM.write(EEPROM_DISPLAY_MODE, display_mode);
			big_mode = 0;
			display_mode_clock = 2;

			redraw_volume_display(volume, 1);	// admin forced
		}
#else	// cycle to sleep count-down display if BF not installed
		display_mode = EEPROM_DISP_MODE_SLEEP;
		EEPROM.write(EEPROM_DISPLAY_MODE, display_mode);
		display_mode_clock = 2;

		redraw_volume_display(volume, 1);	// admin forced
#endif	// USE_BIGFONTS
	}
#ifdef USE_BIGFONTS
	else if (display_mode == EEPROM_DISP_MODE_BIGFONTS) {
		display_mode = EEPROM_DISP_MODE_SLEEP;
		EEPROM.write(EEPROM_DISPLAY_MODE, display_mode);
		big_mode = 0;
		display_mode_clock = 2;

		lcd.clear();
		lcd.cgram_load_normal_bargraph();
		lcd.clear();	// 2 clear's to get rid of any screen garbage

		common_startup(1);
	}
#endif
	else if (display_mode == EEPROM_DISP_MODE_SLEEP) {
#ifdef USE_DS1302_RTC
		if (option_ds1302_rtc_installed == RTC_INSTALLED) {
			// cycle to last item
			display_mode = EEPROM_DISP_MODE_CLOCK;
			display_mode_clock = 1;
		} 
		else
#endif
		{
			// cycle around to top
			display_mode = EEPROM_DISP_MODE_BARGRAPH;
			display_mode_clock = 0;
		}

		EEPROM.write(EEPROM_DISPLAY_MODE, display_mode);

#ifdef USE_BIGFONTS
		big_mode = 0;
#endif
		last_clock_update = 0;    // trigger a redraw;
		redraw_volume_display(volume, 1);  // admin forced
	}
	else if (display_mode == EEPROM_DISP_MODE_CLOCK) {
		// go back to normal db display mode
		display_mode = EEPROM_DISP_MODE_BARGRAPH;
		EEPROM.write(EEPROM_DISPLAY_MODE, display_mode);
#ifdef USE_BIGFONTS
		big_mode = 0;
#endif
		display_mode_clock = 0;

		redraw_volume_display(volume, 1);  // admin forced
	}

	delay(400);  // key debounce
}


void
cycle_between_output_toggle_radio_modes(void)
{
	// print message for start of new mode
	notify_user_1(fl_st_multiout, LCD_CURS_POS_L1_HOME);
         
	// change to the other mode
	if (output_mode_radio_or_toggle == OUTPUT_MODE_RADIO) {
		// flip it
		output_mode_radio_or_toggle = OUTPUT_MODE_TOGGLE;
		//EEPROM.write(EEPROM_OUTPUT_RB_TB, output_mode_radio_or_toggle);
		notify_user_2(fl_st_status_on, 0);
		delay(1000);

		change_output_selector(output_selector, output_selector_mask);
	}
	else {
		// flip it
		output_mode_radio_or_toggle = OUTPUT_MODE_RADIO;
		//EEPROM.write(EEPROM_OUTPUT_RB_TB, output_mode_radio_or_toggle);
		notify_user_2(fl_st_status_off, 0);
		delay(1000);

		// if the user toggled back to single from multi, use
		// the last output selector the user had, then
		output_selector      = last_saved_out_sel;
		output_selector_mask = last_saved_out_sel_mask;
		change_output_selector(output_selector, output_selector_mask);
	}
  
	lcd.clear();
	common_startup(1);
}


// banner_num is from 0..3 (four 8-byte pieces)
void
eeprom_read_banner_name(int banner_num)
{
	byte	sb;

	// copy whole string section from EEPROM to RAM
	for (sb = 0; sb < LEN_BANNER_STRING; sb++) {
		string_buf[sb] = EEPROM.read(EEPROM_USER_BANNER_BASE +
			 (banner_num * LEN_BANNER_STRING) + sb
		);
	}

	string_buf[LEN_BANNER_STRING] = '\0';	// term the string
}


int
search_eeprom_for_IR_code(void)
{
	int		idx;
	unsigned long	val;

#ifdef ALSO_SEARCH_CACHE
	// first search our in-memory cache
	for (idx = 0; // (IFC_VOL_UP_FAST - IFC_VOL_UP_FAST);
	     idx < 5; // (IFC_MUTE_ONOFF - IFC_VOL_UP_FAST);
	     idx++) {
		if (key == ir_keypress_cache[idx]) {
			return idx;
		}
	}
#endif

	for (idx = 5; idx < MAX_FUNCTS; idx++) {
		// search from the fifth element (ha!) since the
		// first 5 are cached in memory
		// (else 'big bada-boom!')
		val = EEread_long(
			EEPROM_IR_LEARNED_BASE_BANK + (idx * sizeof(long))
		);
		if (key == val) {	// key was the IR-sensed longword.
			return idx;
		}
	}

	return -1;	// not found
}


void
read_IR_learned_keys_from_eeprom(void)
{
	int	idx;

	/*
	 * just read the most popular (5) into RAM and keep the rest in EEPROM.
	 * to search, look in RAM first and if no hits found, search in EEPROM.
	 * this will save us a lot of RAM and not cost us much runtime delays
	 * since the keys stored in EEPROM are the least-used and don't need
	 * fast interactive (auto repeat) response times
	 */
	for (idx = IFC_VOL_UP_FAST; idx <= IFC_MUTE_ONOFF; idx++) {
		ir_keypress_cache[idx] = EEread_long(
			EEPROM_IR_LEARNED_BASE_BANK + (idx * sizeof(long))
		);
	}
}


void
recalc_volume_range(void)
{
	// re-read just to be sure we are current with the latest
	installed_relay_count = EEPROM.read(EEPROM_NUM_RELAYS);
	// for 7 relays, this would be 128-1 = 127
	max_byte_size = (1 << installed_relay_count) - 1;
	option_db_step_size = EEPROM.read(EEPROM_DB_STEPSIZE);

	min_vol = EEPROM.read(EEPROM_VOL_MIN_LIMIT);
	max_vol = EEPROM.read(EEPROM_VOL_MAX_LIMIT);

	// fixup max_vol if it's over our byte_size
	if (max_vol > max_byte_size) {
		max_vol = max_byte_size;
		EEPROM.write(EEPROM_VOL_MAX_LIMIT, max_vol);
	}

	// handle any misconfigs in min/max
	if (min_vol > max_vol) {
		min_vol = 0;
		EEPROM.write(EEPROM_VOL_MIN_LIMIT, min_vol);
		max_vol = max_byte_size;
		EEPROM.write(EEPROM_VOL_MAX_LIMIT, max_vol);
	}

	vol_span = abs(max_vol - min_vol);
}


void
read_eeprom_oper_values(void)
{
	char	*p = NULL;

	/*
	 * fix version number in 2nd banner, if necessary
	 */
	eeprom_read_banner_name(1);
	p = string_buf + 12;
	if (strncmp(string_buf, "Volu-Master ", 12) == 0 &&
	    *p >= '0' && *p <= '0' &&
	    *(++p) == '.' &&
	    *(++p) >= '0' && *p <= '9') {
		p = (char *) pgm_read_word(
			&(fl_st_screen_fields[ROMVERSION_STRING_IDX])
		);
		eeprom_write_16_bytes(EEPROM_USER_BANNER2,
				      p, LEN_BANNER_STRING);
	}

	/*
	 * (re)read operational values from EEPROM
	 */
	recalc_volume_range();

	// last-state of power on/off
	//power = EEPROM.read(EEPROM_POWER);

	// coarse volume control step size
	vol_coarse_incr = EEPROM.read(EEPROM_VOLSTEP_COARSE);

	// in case our eeprom version says a 'very large number',
	// don't keep the user waiting THAT long ;)
	if (EEPROM.read(EEPROM_POWERON_DELAY) > 30)
		EEPROM.write(EEPROM_POWERON_DELAY, 30);

	// realtime clock chip support
#ifdef USE_DS1302_RTC
	// user installed this (soldered) or not
	option_ds1302_rtc_installed = EEPROM.read(EEPROM_DS1302_INSTALLED);
	if (option_ds1302_rtc_installed != RTC_INSTALLED)
#else
	option_ds1302_rtc_installed = RTC_UNINSTALLED;
#endif

	/*
	 * input selector and matching volume
	 */
	input_selector = EEPROM.read(EEPROM_INPUT_SEL);
	if (input_selector > (MAX_IOPORTS-1)) {
		// if crazy value, force it to be the first port
		input_selector = 0;
		//EEPROM.write(EEPROM_INPUT_SEL, input_selector);
	}

	volume = 000;
  
	if (volume > max_vol)
		volume = max_vol;
	if (volume < min_vol)
		volume = min_vol;

	//EEPROM.write(EEPROM_PORT_VOL_BASE+input_selector, volume);

	/*
	 * output selector AND its mask
	 */
	output_selector = 000;
	output_selector_mask = 000;
	output_mode_radio_or_toggle = 000;

	if (output_selector > (MAX_IOPORTS-1)) {
		// pick the last port, by default
		output_selector = MAX_IOPORTS-1;
		// we count ports from the left of the byte,
		// so 'human' port 1 == bit7
		output_selector_mask = 1 << (7-output_selector);
		//EEPROM.write(EEPROM_OUTPUT_SEL, output_selector);
		//EEPROM.write(EEPROM_OUTPUT_SEL_MASK, output_selector_mask);
	}

	last_saved_out_sel = output_selector;
	last_saved_out_sel_mask = output_selector_mask;

	/*
	 * number of delta1 boards installed configuration
	 */

	// Read config from EEPROM
	option_delta1_board_count = EEPROM.read(EEPROM_NUM_DELTA1_BOARDS);

#if !defined(USE_D1_RELAYS) && !defined(USE_PGA_I2C)
	// If neither delta1 nor PGA support is compiled in, then
	// disable volume control functionality.
	option_delta1_board_count = 0;
	EEPROM.write(EEPROM_NUM_DELTA1_BOARDS, 0);
#endif

#if !defined(USE_D1_RELAYS) && defined(USE_PGA_I2C)
	// If delta1 support not compiled in but PGA is, then force
	// PGA setting and update EEPROM.
	if (option_delta1_board_count > 0 && option_delta1_board_count < 3) {
		option_delta1_board_count = 3;
		EEPROM.write(EEPROM_NUM_DELTA1_BOARDS, 3);
	}
#endif

#if defined(USE_D1_RELAYS) && !defined(USE_PGA_I2C)
	// If delta1 support is compiled in but not PGA, then force
	// "1 d1" setting and update EEPROM.
	if (option_delta1_board_count > 2) {
		option_delta1_board_count = 1;
		EEPROM.write(EEPROM_NUM_DELTA1_BOARDS, 1);
	}
#endif

	/*
	 * number of delta2 boards installed configuration
	 */

	// Read config from EEPROM
	option_delta2_board_count = EEPROM.read(EEPROM_NUM_DELTA2_BOARDS);

#if !defined(USE_D2_RELAYS) && !defined(USE_SPDIF)
	// If neither delta2 nor spdif support is compiled in, then
	// disable i/o selector functionality.
	option_delta2_board_count = 0;
	EEPROM.write(EEPROM_NUM_DELTA2_BOARDS, 0);
#endif

#if !defined(USE_D2_RELAYS) && defined(USE_SPDIF)
	// If delta2 support not compiled in but SPDIF is, then force
	// "S-Addr" setting and update EEPROM.
	if (option_delta2_board_count > 0 && option_delta2_board_count < 3) {
		option_delta2_board_count = 3;
		EEPROM.write(EEPROM_NUM_DELTA2_BOARDS, 3);
	}
#endif

#if defined(USE_D2_RELAYS) && !defined(USE_SPDIF)
	// If delta2 support is compiled in but not SPDIF, then force
	// "1 d2" setting and update EEPROM.
	if (option_delta2_board_count > 2) {
		option_delta2_board_count = 1;
		EEPROM.write(EEPROM_NUM_DELTA2_BOARDS, 1);
	}
#endif

#ifdef USE_X10
	// not implemented yet
	option_x10_firecracker = 0;
#endif

	/*
	 * motor pot
	 */
	option_motor_pot_installed = EEPROM.read(EEPROM_MOTOR_ENABLED);
	option_pot_installed = EEPROM.read(EEPROM_POT_ENABLED); 

#ifdef USE_MOTOR_POT
	pot_state = MOTOR_INIT;
	digitalWrite(MOTOR_POT_ROTATE_CCW, LOW);    // stop turning right
	digitalWrite(MOTOR_POT_ROTATE_CW,  LOW);    // stop turning left
#endif
  
	/*
	 * i2c addr table for our PE chips
	 */

#if defined(USE_D1_RELAYS) || defined(USE_PGA_I2C)
	// d1
	delta_i2c_addr[0] = EEPROM.read(EEPROM_I2C_D1_B1_H);
	delta_i2c_addr[1] = EEPROM.read(EEPROM_I2C_D1_B1_L);
	delta_i2c_addr[2] = EEPROM.read(EEPROM_I2C_D1_B2_H);
	delta_i2c_addr[3] = EEPROM.read(EEPROM_I2C_D1_B2_L);
#endif

#if defined(USE_D2_RELAYS) || defined(USE_SPDIF)
	// d2
	delta_i2c_addr[4] = EEPROM.read(EEPROM_I2C_D2_B1_H);
	delta_i2c_addr[5] = EEPROM.read(EEPROM_I2C_D2_B1_L);
	delta_i2c_addr[6] = EEPROM.read(EEPROM_I2C_D2_B2_H);
	delta_i2c_addr[7] = EEPROM.read(EEPROM_I2C_D2_B2_L);
#endif

	/*
	 * LCD backlight
	 */
	lcd.backlight_min = EEPROM.read(EEPROM_BACKLIGHT_MIN);
	lcd.backlight_max = EEPROM.read(EEPROM_BACKLIGHT_MAX);
	lcd.backlight_bright_mode = EEPROM.read(EEPROM_BACKLIGHT_MODE);
}


void
init_port_structs_eeprom(void)
{
	byte	i;

	/*
	 * ports table (8 entries, back to back, starting at
	 * EEPROM_PORTS_TABLE_BASE
	 */
	for (i = 0; i < MAX_IOPORTS; i++) {
		/*
		 * set default for this port
		 */

		// volume level (0 = mute level)
		EEPROM.write(EEPROM_PORT_VOL_BASE+i, 0);

		// first 4 ports are inputs, by default, last 4 are outputs.
		if (i < 4) {
			EEPROM.write(EEPROM_PORT_STATE_BASE+i,
				     PORT_AS_INPUT);
			strcpy_P(string_buf, fl_st_input);
		}
		else {
			EEPROM.write(EEPROM_PORT_STATE_BASE+i,
				     PORT_AS_OUTPUT);
			strcpy_P(string_buf, fl_st_output);
		}

		sprintf(string_buf, "%s %c", string_buf, '1' + i);

		// save the string_buf[] to eeprom at the right place,
		// for 8 bytes
		eeprom_write_port_name(i);
	}
}


void
init_all_eeprom(void)
{
	char	*p = NULL;

	EEPROM.write(EEPROM_VERSION, 0x01);

	power = POWER_ON;
	//EEPROM.write(EEPROM_POWER, power);

	/*
	 * in/out selectors and their bitmasks
	 */
	// pick the first input (first actual port == port0, so that's 0x00)
	input_selector = 0;
	EEPROM.write(EEPROM_INPUT_SEL, input_selector);

	// pick the 2nd last port as the default output port
	// (just to have something valid)
	output_selector = 7;
	output_selector_mask = (1 << (7 - output_selector));
	EEPROM.write(EEPROM_OUTPUT_SEL, output_selector);
	EEPROM.write(EEPROM_OUTPUT_SEL_MASK, output_selector_mask);

	output_mode_radio_or_toggle = OUTPUT_MODE_RADIO;
	EEPROM.write(EEPROM_OUTPUT_RB_TB, output_mode_radio_or_toggle);

	/*
	 * volume control
	 */
	// fine volume control step size
	option_db_step_size = DEFAULT_DB_STEPSIZE;
	EEPROM.write(EEPROM_DB_STEPSIZE, option_db_step_size);

	// coarse volume control step size
	vol_coarse_incr = DEFAULT_VOL_COARSE_INCR;
	EEPROM.write(EEPROM_VOLSTEP_COARSE, vol_coarse_incr);

	// things that depend on # of installed relays (in d1 board)
	installed_relay_count = DEFAULT_RELAY_COUNT;	// 8;
	EEPROM.write(EEPROM_NUM_RELAYS, installed_relay_count);

	// for 7 relays, this would be 128-1 = 127
	max_byte_size = (1 << installed_relay_count) - 1;

	// volume control range
	min_vol = 0;
	EEPROM.write(EEPROM_VOL_MIN_LIMIT, min_vol);

	max_vol = max_byte_size;
	EEPROM.write(EEPROM_VOL_MAX_LIMIT, max_vol);

	/*
	 * real-time clock
	 */
#ifdef USE_DS1302_RTC
	// the RTC (realtime clock chip)
	option_ds1302_rtc_installed = RTC_INSTALLED;
#else
	option_ds1302_rtc_installed = RTC_UNINSTALLED;
#endif
	EEPROM.write(EEPROM_DS1302_INSTALLED, option_ds1302_rtc_installed);

	/*
	 * LCD backlight
	 */
	lcd.backlight_min = MIN_BL_LEVEL;
	EEPROM.write(EEPROM_BACKLIGHT_MIN, lcd.backlight_min);

	lcd.backlight_max = DEFAULT_BL_LEVEL;
	EEPROM.write(EEPROM_BACKLIGHT_MAX, lcd.backlight_max);

	lcd.set_backlight(lcd.backlight_max);	// show it, for real

	lcd.backlight_bright_mode = BACKLIGHT_MODE_FULL_BRIGHT;
	EEPROM.write(EEPROM_BACKLIGHT_MODE, lcd.backlight_bright_mode);

	/*
	 * pot, motorpot, ir blaster
	 */
#ifdef USE_MOTOR_POT
	option_motor_pot_installed = 1;
	EEPROM.write(EEPROM_MOTOR_ENABLED, option_motor_pot_installed);
#endif

#ifdef USE_ANALOG_POT
	option_pot_installed = 1;
	EEPROM.write(EEPROM_POT_ENABLED, option_pot_installed);
#endif

#ifdef USE_IRBLASTER
	// if the IR blaster is installed (not supported in v1.0x)
	EEPROM.write(EEPROM_IRTX_ENABLED, 0);
#endif

#ifdef USE_X10
	// if the x10 firecracker module is installed
	option_x10_firecracker = 0;
	EEPROM.write(EEPROM_X10_ENABLED, option_x10_firecracker);
#endif // USE_X10

	/*
	 * delta1 section
	 */
#if defined(USE_D1_RELAYS) && !defined(USE_PGA_I2C)
	option_delta1_board_count = DEFAULT_DELTA1_BOARD_COUNT;  // 0..3
#endif
#if !defined(USE_D1_RELAYS) && defined(USE_PGA_I2C)
	option_delta1_board_count = 3;	// 0..3
#endif
#if defined(USE_D1_RELAYS) && defined(USE_PGA_I2C)
	option_delta1_board_count = DEFAULT_DELTA1_BOARD_COUNT;  // 0..3
#endif
	EEPROM.write(EEPROM_NUM_DELTA1_BOARDS, option_delta1_board_count);

	/*
	 * default factory i2c addrs
	 */
#if defined(USE_D1_RELAYS) || defined(USE_PGA_I2C)
	delta_i2c_addr[0] = DEFAULT_DELTA1_I2C_ADDR_0;
	delta_i2c_addr[1] = DEFAULT_DELTA1_I2C_ADDR_1;
	delta_i2c_addr[2] = DEFAULT_DELTA1_I2C_ADDR_2;
	delta_i2c_addr[3] = DEFAULT_DELTA1_I2C_ADDR_3;

	EEPROM.write(EEPROM_I2C_D1_B1_H, delta_i2c_addr[0]);
	EEPROM.write(EEPROM_I2C_D1_B1_L, delta_i2c_addr[1]);
	EEPROM.write(EEPROM_I2C_D1_B2_H, delta_i2c_addr[2]);
	EEPROM.write(EEPROM_I2C_D1_B2_L, delta_i2c_addr[3]);
#endif

	/*
	 * delta2 section
	 */
	option_delta2_board_count = 1; // DEFAULT_DELTA2_BOARD_COUNT;  // 0..4
	EEPROM.write(EEPROM_NUM_DELTA2_BOARDS, option_delta2_board_count);

	/*
	 * default factory i2c addrs
	 */
#if defined(USE_D2_RELAYS) || defined(USE_SPDIF)
	delta_i2c_addr[4] = DEFAULT_DELTA2_I2C_ADDR_0;
	delta_i2c_addr[5] = DEFAULT_DELTA2_I2C_ADDR_1;
	delta_i2c_addr[6] = DEFAULT_DELTA2_I2C_ADDR_2;
	delta_i2c_addr[7] = DEFAULT_DELTA2_I2C_ADDR_3;

	EEPROM.write(EEPROM_I2C_D2_B1_H, delta_i2c_addr[4]);
	EEPROM.write(EEPROM_I2C_D2_B1_L, delta_i2c_addr[5]);
	EEPROM.write(EEPROM_I2C_D2_B2_H, delta_i2c_addr[6]);
	EEPROM.write(EEPROM_I2C_D2_B2_L, delta_i2c_addr[7]);
#endif

	/*
	 * display mode
	 */
	display_mode = EEPROM_DISP_MODE_BARGRAPH;
	EEPROM.write(EEPROM_DISPLAY_MODE, display_mode);

	// eeprom saving of last used menu page/node
	EEPROM.write(EEPROM_MENU_PGNUM, 0);
	EEPROM.write(EEPROM_MENU_NODENUM, 0);

	// default sleep interval
	EEPROM.write(EEPROM_SLEEP_INTERVAL, DEFAULT_SLEEP_INTERVAL);

	// how long to wait on mute before unmute at power-on
	EEPROM.write(EEPROM_POWERON_DELAY, DEFAULT_POWER_ON_AMP_DELAY);

#if 0	// not yet implemented
	// lcd display, physical
	display_type = DEFAULT_DISPLAY_TYPE;	// from EEPROM_DISPLAY_LCD_VFD
	EEPROM.write(EEPROM_DISPLAY_LCD_VFD, DEFAULT_DISPLAY_TYPE);

	display_size = DEFAULT_DISPLAY_SIZE;	// from EEPROM_DISPLAY_SIZE
	EEPROM.write(EEPROM_DISPLAY_SIZE, DEFAULT_DISPLAY_SIZE);
#endif

	/*
	 * init user banner area (copy our flash strings to EEPROM, first)
	 */

	/*
	 * first line of banner
	 */
	p = (char *) pgm_read_word(
		&(fl_st_screen_fields[ROMTITLE_STRING_IDX])
	);
	eeprom_write_16_bytes(EEPROM_USER_BANNER1, p, LEN_BANNER_STRING);

	/*
	 * 2nd line of banner
	 */
	p = (char *) pgm_read_word(
		&(fl_st_screen_fields[ROMVERSION_STRING_IDX])
	);
	eeprom_write_16_bytes(EEPROM_USER_BANNER2, p, LEN_BANNER_STRING);

	/*
	 * port names, in/out/disabled status, etc
	 */
	init_port_structs_eeprom();
}


//===================  System Initialization Routine ======================//

void 
init_system(void)
{
	/*
	 * get the IR keycodes that we previously learned
	 */
	read_IR_learned_keys_from_eeprom();

	/*
	 * we do this on power-on but also whenever any EEPROM value changes,
	 * just to be sure we are all in sync
	 */
	read_eeprom_oper_values();

	/*
	 * init various globals
	 */
	sleep_mode = 0;
	half_minutes = 0;
	last_sleep_time_display_minutes = 0;

	// this controls the overal top 'mode' that we are running at
	toplevel_mode = TOPLEVEL_MODE_NORMAL;

	// cache and timeout of eeprom writes due to vol control value changing
	eewrite_cur_vol_dirtybit = 0;   // validate the cache for vol_level
	eewrite_cur_vol_ts = 0;

#ifdef USE_ANALOG_POT
	// save a snapshot of the current pot value so that when we
	// enter a field, we won't suddenly think a value changed on us
	if (option_pot_installed == 1) {
		last_seen_pot_value = read_analog_pot_with_smoothing(
			SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
		); 
	}
#endif
}


void
turn_on_power_relay(void)
{
#ifdef USE_X10
	if (option_x10_firecracker == 1)
		X10_turn_power_on();
#endif

#ifdef USE_POWER_RELAY
	digitalWrite(RELAY_POWER_PIN, HIGH);
#endif
}


void
turn_off_power_relay(void)
{
#ifdef USE_X10
	if (option_x10_firecracker == 1)
		X10_turn_power_off();
#endif

#ifdef USE_POWER_RELAY
	digitalWrite(RELAY_POWER_PIN, LOW);
#endif
}


// line 1 or 2
void
get_and_draw_logo_line(byte logo_line_num)
{
	byte	i;

	for (i = 0; i < LEN_BANNER_STRING; i++) {
		string_buf[i] = EEPROM.read(
			EEPROM_USER_BANNER_BASE +
			((logo_line_num-1) * LEN_BANNER_STRING) + i
		);
	}

	string_buf[LEN_BANNER_STRING] = '\0';	// safety

	if (logo_line_num == 1) {
		lcd.send_string(string_buf, LCD_CURS_POS_L1_HOME);
	} 
	else if (logo_line_num == 2) {
		lcd.send_string(string_buf, LCD_CURS_POS_L2_HOME);
	}
}


byte
scan_front_button(void)
{
	byte	in_keys = lcd.ReadInputKeys();

	if ((in_keys & LCD_MCP_INPUT_PINS_MASK) != LCD_MCP_INPUT_PINS_MASK) {
		return 1;
	} 
	else {
		return 0;
	}
}


void 
signon_msg(void)
{  
#ifdef USE_MEM_CHECKER
	unsigned int	mem_used;
#endif

	lcd.clear();
	lcd.fade_backlight_on();

#ifdef USE_MEM_CHECKER
	/*
	 * if enabled, show remaining (avail) memory to lcd
	 */
	// mem_used = freeMemory();
	// mem_used = availableMemory();
	// (void)availableMemory();
	// sprintf(string_buf, "sp=%u hp=%u", stackptr, heapptr);
	// lcd.send_string(string_buf, LCD_CURS_POS_L1_HOME);
	// delay(2000);
	// lcd.clear();
#endif

	/*
	 * get both user-settable banner strings from EEPROM
	 */
	get_and_draw_logo_line(1);
	get_and_draw_logo_line(2);
}


byte
check_config_button_with_timeout(void)
{
	unsigned long	start_time = millis();
  
	// scan the power/config button; this gets us into the
	// 'config' mode at power-on
	while (abs(millis() - start_time) <= SPLASHSCRNTIME) {	// 3 seconds
		if (scan_front_button() == 1) {
			return 1;  // 1 means the user did press the button
		}
		delay(20);
	}

	return 0;   // button not pressed in timeout_period amount of time
}


void
pad_string_buf_with_spaces(byte count)
{
	for (byte i = 0; i < count; i++) {
		string_buf[i]=' ';
	}

	string_buf[count] = '\0';	// terminate
}


void
menu_draw_label(void)
{
	char	*p = NULL;
	byte	str_table_index;
	byte	sb;
	byte	c;

	// draw the label part of the menu

        // set cursor pos (row, col)
	lcd.cursorTo((label_nodes[data_idx].line)-1,
		     (label_nodes[data_idx].col)-1);

	// labels have 'st8_addr' since its 'stringtable8' in flash and
	// NOT eeprom
	str_table_index = label_nodes[data_idx].st8_addr;

	// get text from FLASH into working mem (string_buf)
	p = (char *) pgm_read_word(&(fl_st_screen_fields[str_table_index]));

	for (sb = 0; sb < STRING_BUF_MAXLEN; sb++) {
		c = pgm_read_byte(p++);
		string_buf[sb] = c;
		if (c == '\0')
			break;	// exit if we hit a null before 8 chars
	}

	lcd.send_string(string_buf, 0);   // display text at current cursor pos
}


// this is, effectively, an object oriented 'printMe()' routine.
// it handles string values in string_buf[] in ascii.
void
menu_draw_string(byte blink_flag)
{
	byte	line;
	byte	col;

	/*
	 * test for portname sections
	 */

	// which port name sections is this?
	if (data_idx >= PORTNAME_DATA_IDX_START &&
	    data_idx <= PORTNAME_DATA_IDX_END) {
		eeprom_read_port_name(data_idx - PORTNAME_DATA_IDX_START);
	}

	/*
	 * test for banner sections
	 */
  
	// which of the 2 banner sections is this?
	if (data_idx >= BANNER_DATA_IDX_START &&
	    data_idx <= BANNER_DATA_IDX_END) {
		eeprom_read_banner_name(data_idx - BANNER_DATA_IDX_START);
	}

	// the string is being edited in-RAM
	// (it's there already for us in 'string_buf')
	line = tf8_nodes[data_idx].line - 1;
	col  = tf8_nodes[data_idx].col - 1;	// set cursor pos (row, col)
	lcd.cursorTo(line, col);		// set cursor pos (row, col)
	lcd.send_string(string_buf, 0);

	// if it's time to blink, draw a block over the current cursor char
	if (blink_flag == 1) {
		lcd.cursorTo(line, col + current_cursor_pos);
		lcd.write(0xff);		// cursor char
	}
}


// this is, effectively, an object oriented 'printMe()' routine.
// it handles enum values and expands their codes to string_buf[] in ascii.
void
menu_draw_int(byte blink_flag)
{
	static char	binary_ascii_buf[17];
	byte		j;
	byte		half_db_flag;

	// get byte value from EEPROM into working mem

#ifdef USE_DS1302_RTC
	// special case: if this is time (hh,mm,ss) then read from
	// our RTC registers instead of real eeprom
	if (eeprom_index == EEPROM_TIME_HH)
		menu_edited_byte_var = my_hrs;
	else if (eeprom_index == EEPROM_TIME_MM)
		menu_edited_byte_var = my_mins;
	else if (eeprom_index == EEPROM_TIME_SS)
		menu_edited_byte_var = my_secs;
	else
#endif
		menu_edited_byte_var = EEPROM.read(eeprom_index);

	// start off in max brightness mode
	lcd.set_backlight(lcd.backlight_max);

	/*
	 * backlight live processing
	 */
	if (eeprom_index == EEPROM_BACKLIGHT_MIN) {
		lcd.backlight_min = menu_edited_byte_var;
		lcd.set_backlight(lcd.backlight_min);	// show it, for real
	}
	else if (eeprom_index == EEPROM_BACKLIGHT_MAX) {
		lcd.backlight_max = menu_edited_byte_var;
	}

	/*
	 ************************* begin of special cases *********************
	 */

	/*
	 * special case: coarse volume increment up/down values
	 */
	if (eeprom_index == EEPROM_VOLSTEP_COARSE) {
		// convert the byte value to printable ascii
		// for half-db relays OR for PGA installs
		if (option_db_step_size == DB_STEPSIZE_HALF ||
		    option_delta1_board_count == 3) {
			if (menu_edited_byte_var & 0x01)
				// on odd numbers, set the 'we need a
				// .5dB printout' flag
				half_db_flag = '5';
			else
				// even numbers, we print a .0dB instead
				half_db_flag = '0';

			sprintf(string_buf, "%3d.%c",
				menu_edited_byte_var >> 1, half_db_flag);

		}
		else if (option_db_step_size == DB_STEPSIZE_WHOLE)
			sprintf(string_buf, "  %3d", menu_edited_byte_var);
		else
			sprintf(string_buf, " %2d.%d",
				menu_edited_byte_var/10,
				menu_edited_byte_var % 10);

		strcat(string_buf, "dB");
	}	// large step-size

	/*
	 * special case: volume min,max values
	 */
	else if (eeprom_index == EEPROM_VOL_MIN_LIMIT ||
		 eeprom_index == EEPROM_VOL_MAX_LIMIT) {
		// convert the byte value to printable ascii
		format_volume_to_string_buf(menu_edited_byte_var, string_buf);
	}	// vol min,max

	/*
	 * special case: db/step enum mapping (0=0.1db, 1=0.5db, 2=1.0db)
	 */
	else if (eeprom_index == EEPROM_DB_STEPSIZE) {
		if (menu_edited_byte_var == DB_STEPSIZE_TENTH)
			strcpy_P(string_buf, fl_st_db_tenth);
		else if (menu_edited_byte_var == DB_STEPSIZE_HALF)
			strcpy_P(string_buf, fl_st_db_half);
		else if (menu_edited_byte_var == DB_STEPSIZE_WHOLE)
			strcpy_P(string_buf, fl_st_db_whole);
	}	// db/step enum magic

	/*
	 * special case: delta1 (vol engine, now) board count OR PGA prototype
	 */
	else if (eeprom_index == EEPROM_NUM_DELTA1_BOARDS) {
		// the 3 delta1 variants
		if (menu_edited_byte_var == 0)
			strcpy_P(string_buf, fl_st_na);  // 'n/a'
#if defined(USE_D1_RELAYS) || defined(USE_PGA_I2C)
		else if (menu_edited_byte_var == 1)
			strcpy_P(string_buf, fl_st_vol_eng_d1_1);
		else if (menu_edited_byte_var == 2)
			strcpy_P(string_buf, fl_st_vol_eng_d1_2);
#endif

#ifdef USE_PGA_I2C
		// the PGA variant
		else if (menu_edited_byte_var == 3)
			strcpy_P(string_buf, fl_st_vol_eng_pga_1);
#endif
	}	// vol-engine (d1 board count) enum magic

	/*
	 * special case: port enum mapping (0=out, 1=in, 2=disabled)
	 */
	else if (eeprom_index >= EEPROM_PORT_STATE_BASE &&
		 eeprom_index <= (EEPROM_PORT_STATE_BASE+7)) {
		if (menu_edited_byte_var == PORT_AS_OUTPUT)
			strcpy_P(string_buf, fl_st_output);
		else if (menu_edited_byte_var == PORT_AS_INPUT)
			strcpy_P(string_buf, fl_st_input);
		else
			strcpy_P(string_buf, fl_st_na);
	}	// port state enum magic

	/*
	 * special case: delta2 (io engine, now) board count OR spdif prototype
	 */
	else if (eeprom_index == EEPROM_NUM_DELTA2_BOARDS) {
		// the 3 delta2 variants
		if (menu_edited_byte_var == 0)
			strcpy_P(string_buf, fl_st_na);  // 'n/a'
#if defined(USE_D2_RELAYS) || defined(USE_SPDIF)
		else if (menu_edited_byte_var == 1)
			strcpy_P(string_buf, fl_st_io_eng_d2_1);
		else if (menu_edited_byte_var == 2)
			strcpy_P(string_buf, fl_st_io_eng_d2_2);
#endif

#ifdef USE_SPDIF
		// the 2 spdif variants
		else if (menu_edited_byte_var == 3)
			strcpy_P(string_buf, fl_st_io_eng_spdif_addr);
		else if (menu_edited_byte_var == 4)
			strcpy_P(string_buf, fl_st_io_eng_spdif_mask);
#endif
	}	// io-engine (d2 board count) enum magic

	/*
	 * special case: i2c address fields
	 */
	else if (eeprom_index >= EEPROM_I2C_D1_B1_H &&
		 eeprom_index <= EEPROM_I2C_D2_B2_L) {
		// convert to printable-binary 
		dec2bin(menu_edited_byte_var, 7, binary_ascii_buf);

		// print in both decimal and binary (so friendly!)
		sprintf(string_buf, "%03d %s",
			menu_edited_byte_var, binary_ascii_buf);
	}	// i2c address

	/*
	 * not a 'special' integer so we just print it's internal
	 * value directly
	 */
	else if (int_nodes[data_idx].len == 1)
		sprintf(string_buf, "%d", menu_edited_byte_var);
	else if (int_nodes[data_idx].len == 2)
		sprintf(string_buf, "%02d", menu_edited_byte_var);
	else if (int_nodes[data_idx].len == 3)
		sprintf(string_buf, "%03d", menu_edited_byte_var);

	/*
	 * common exit for all things that set string_buf[]
	 */

	// go to the screen (x,y) place for this integer

	// set cursor pos (row, col)
	lcd.cursorTo((int_nodes[data_idx].line)-1,
		     (int_nodes[data_idx].col)-1);

	for (j = 0; j < int_nodes[data_idx].len; j++) {
		// pad to the right with spaces if data < 8 chars wide
		lcd.write(' ');
	}

	// set cursor pos (row, col)
	lcd.cursorTo((int_nodes[data_idx].line)-1,
		     (int_nodes[data_idx].col)-1);
	// display text at current cursor pos
	lcd.send_string(string_buf, 0);

	// draw a cursor over the current char position if it's
	// 'blink time' this time
	if (blink_flag == 1) {
		lcd.cursorTo(
			(int_nodes[data_idx].line)-1,
			(int_nodes[data_idx].col) - 1 + current_cursor_pos
		);

		if (data_type == D_INTEGER) {
			// 'highlight' the WHOLE field
			for (j = 0; j < strlen(string_buf); j++) {
				lcd.write(0xff);	// block cursor char
			}
		}
		else {	// D_STRING type
			// 'highlight' only the current cursor pos
			lcd.write(0xff);		// block cursor char
		}
	}
}


// a convenience dispatcher routine; calls *int or *string
// depending on data type
void
menu_draw_data(byte blink_flag)
{
	if (data_type == D_STRING) {		// draw the STRING value field
		menu_draw_string(blink_flag);
	} 
	else if (data_type == D_INTEGER) {	// draw the INTEGER value field
		menu_draw_int(blink_flag);
	}
}


// just sets the cursor position variable to the data field start (ie, 0)
void
menu_find_start_of_word(void)
{
	current_cursor_pos = 0;		// init our cursor pos to
					// 'start of word'
}


// returns the data field length (in bytes or chars)
int
menu_find_data_len(void)
{
	if (data_type == D_INTEGER) {
		return (int_nodes[data_idx].len);
	} 
	else if (data_type == D_STRING) {
		return (tf8_nodes[data_idx].len);
	}
	return 0;	// default
}


// just sets the cursor position variable to the data field length (chars)
void
menu_find_end_of_word(void)
{
	current_cursor_pos = menu_find_data_len(/*current_menu_node*/) - 1;
}


void
menu_find_prev_data_field(void)
{
	current_cursor_pos = 0;	// init our cursor pos to 'start of word'

	if (current_menu_node == g_starting_data_node_idx) {
		// wrap around to the end
		current_menu_node = g_ending_data_node_idx;
	} 
	else {
		--current_menu_node;
	}
}


void
menu_find_next_data_field(void)
{
	current_cursor_pos = 0;	// init our cursor pos to 'start of word'

	if (current_menu_node == g_ending_data_node_idx) {
		// wrap around to the beginning
		current_menu_node = g_starting_data_node_idx;
	} 
	else {
		++current_menu_node;
	}
}


void
menu_draw_screen(byte screen_idx)
{
	lcd.clear();
	lcd.set_backlight(lcd.backlight_max);	// set to max brightness mode

	current_screen_node = screen_idx;
  
	// this is the range of contiguous 'data' fields that we can
	// 'tab'/circle around
	g_starting_data_node_idx =
		screen_nodes[screen_idx].starting_data_node_idx;
	g_ending_data_node_idx =
		screen_nodes[screen_idx].ending_data_node_idx;

	for (current_menu_node =
		screen_nodes[screen_idx].starting_menu_node_idx;
	     current_menu_node <=
		screen_nodes[screen_idx].ending_menu_node_idx;
	     current_menu_node++) {

		recache_data_index_and_type();

		if (data_type == D_LABEL) {
			menu_draw_label();
		} 
		else if (data_type == D_INTEGER) {
			// we always draw 'screens' from EEPROM since we
			// assume that EEPROM is current after a screen-edit
			menu_draw_int(0);
		} 
		else if (data_type == D_STRING) {
			// we always draw 'screens' from EEPROM since we
			// assume that EEPROM is current after a screen-edit
			menu_draw_string(0);
		}
	}	// for each menu node

	/*
	 * after we draw the whole screen, go back to select the first
	 * non-label field
	 */

	current_menu_node = g_starting_data_node_idx;
	recache_data_index_and_type();

	if (data_type == D_INTEGER) {
		// if type is 'byte', we always put the cursor at end-of-word
		menu_find_start_of_word();
		menu_draw_int(0);
	}
	else if (data_type == D_STRING) {
		// for strings, we put cursor at start-of-word
		menu_find_start_of_word();
		menu_draw_string(0);
	}

#ifdef USE_ANALOG_POT
	// capture a value here so that we can define a 'starting value'
	// for our pot at power-on
	if (option_motor_pot_installed != 1 && option_pot_installed == 1) {
		last_seen_pot_value = read_analog_pot_with_smoothing(
			SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
		);	// to smooth it out
	}
#endif
}


void
init_blink_state(void)
{
	t_start = millis();
	blink_state = 0;
	  
	menu_draw_data(blink_state);
}


void
toggle_blink_state(void)
{
	t_start = millis();		// reset our counter

	if (blink_state == 0) {
		blink_state = 1;	// toggle our state
	} 
	else {
		blink_state = 0;	// toggle our state
	}

	// draw over the screen area with data OR the block cursor
	menu_draw_data(blink_state);
}


void
leaving_field_saving_data(void)
{
#ifdef USE_DS1302_RTC
	/*
	 * HH MM SS (only detect if it's the SS field; and when the user
	 * leaves that field, set that second's value to the RTC chip.
	 */
	if (eeprom_index == EEPROM_TIME_SS) {
		rtc.GetTime();
		// overlay this with the user data
		rtc.Secs = bin2bcd(menu_edited_byte_var);
		// this copies Hrs, Mins, Secs to the clock chip for real
		rtc.SetTime();
	}
#endif

	/*
	 * number of relays (special since others depend on this and
	 * if this changes, other have to auto-update)
	 */
	if (eeprom_index == EEPROM_NUM_RELAYS) {
		installed_relay_count = menu_edited_byte_var;
		EEPROM.write(EEPROM_NUM_RELAYS, menu_edited_byte_var);
		recalc_volume_range();
	}	// num relays

	/*
	 * native engine step-size (half, tenth, whole db)
	 */
	else if (eeprom_index == EEPROM_DB_STEPSIZE) {
		// use the currently edited value
		option_db_step_size = menu_edited_byte_var;
		// save it right away to eeprom
		EEPROM.write(EEPROM_DB_STEPSIZE, option_db_step_size);
		recalc_volume_range();
	}	// stepsize

	/*
	 * all other cases, just copy the edit value to the (eeprom,ram) copies
	 */
	else {
		// copy the working value to EEPROM
		EEPROM.write(eeprom_index, menu_edited_byte_var);
		recalc_volume_range();
	}	// special valued int's

	read_eeprom_oper_values();
}


// formats integer data into string_buf[].
// also handles any special 'side effects' (backlight dimming, etc)
// as well as range-checking (don't let vol_min go above vol_max, etc)
// data_idx is not passed but is assumed to be global and 'always accurate'

void
valuator_byte_update(byte temp_valuator)
{
	// police some of the range values

	if (temp_valuator > int_nodes[data_idx].max_legal)
		temp_valuator = int_nodes[data_idx].max_legal;
	if (temp_valuator < int_nodes[data_idx].min_legal)
		temp_valuator = int_nodes[data_idx].min_legal;

	/*
	 * min and max volume
	 */
	if (eeprom_index == EEPROM_VOL_MIN_LIMIT) {
		if (temp_valuator > max_vol)
			temp_valuator = max_vol;
	}
	else if (eeprom_index == EEPROM_VOL_MAX_LIMIT) {
		if (temp_valuator < min_vol)
			temp_valuator = min_vol;
	}

	/*
	 * backlight live processing
	 */
	else if (eeprom_index == EEPROM_BACKLIGHT_MIN) {
		if (temp_valuator > (lcd.backlight_max-1))
			temp_valuator = (lcd.backlight_max-1);

		// show the current valuator value as backlight brightness
		lcd.set_backlight(temp_valuator);
	} 
	else if (eeprom_index == EEPROM_BACKLIGHT_MAX) {
		if (temp_valuator < (lcd.backlight_min+1))
			temp_valuator = (lcd.backlight_min+1);
	}

	/*
	 * all other processing
	 */
#ifdef USE_DS1302_RTC
	// special case: if this is hh,mm,ss, don't write to eeprom, but
	//  write to the RTC chip, instead

	if (eeprom_index == EEPROM_TIME_HH) {
		rtc.Hrs  = bin2bcd(temp_valuator);
		rtc.Mins = bin2bcd(my_mins);
		rtc.Secs = bin2bcd(my_secs);
		// this copies Hrs, Mins, Secs to the clock chip for real
		rtc.SetTime();
	} 
	else if (eeprom_index == EEPROM_TIME_MM) {
		rtc.Hrs  = bin2bcd(my_hrs);
		rtc.Mins = bin2bcd(temp_valuator);
		rtc.Secs = bin2bcd(my_secs);
		// this copies Hrs, Mins, Secs to the clock chip for real
		rtc.SetTime();
	} 
	else if (eeprom_index == EEPROM_TIME_SS) {
		rtc.Hrs  = bin2bcd(my_hrs);
		rtc.Mins = bin2bcd(my_mins);
		rtc.Secs = bin2bcd(temp_valuator);
		// this copies Hrs, Mins, Secs to the clock chip for real
		rtc.SetTime();
	}
	else
#endif
		// copy the working value to EEPROM
		EEPROM.write(eeprom_index, temp_valuator);

	// force backlight to be max (cleanup of any min-backlight setting)
	if (eeprom_index != EEPROM_BACKLIGHT_MIN)
		lcd.set_backlight(lcd.backlight_max);

	// display the integer value, perhaps in enum expanded format
	menu_draw_int(0);
}


void
recache_data_index_and_type(void)
{
//	data_idx  = menu_nodes[current_menu_node].data_node_idx;
	data_type = menu_nodes[current_menu_node].data_type;
  
	if (data_type == D_INTEGER)
		eeprom_index = int_nodes[data_idx].eeprom_addr;
	else
		eeprom_index = tf8_nodes[data_idx].eeprom_addr;
}


/********************************************************************
 * this is the loop() routine when the user is in menu mode
 *********************************************************************/

void
handle_IR_keys_menu_mode(void)
{
	byte	char_edit = ' ';
	int	sensed_pot_value;
	int	max_legal;
	int	min_legal;

	recache_data_index_and_type();

	/*
	 * blink cursor (if needed)
	 */
	if (blink_state == 0 && abs(millis() - t_start) >= 300) {
		toggle_blink_state();
	} 
	else if (blink_state == 1 && abs(millis() - t_start) >= 200) {
		toggle_blink_state();
	}

#ifdef USE_DS1302_RTC
	if (current_screen_node == SCREEN_ID_SETTIME) {
		// did time change (seconds value changed?)
		rtc.GetTime();
		// copies bcd stuff into binary my_hrs (etc)
		unpack_rtc_bcd_data();
		if (rtc.Secs != last_secs) {
			last_secs = rtc.Secs;
			init_blink_state();
			lcd.command(LCD_CURS_POS_L2_HOME+2);
	
			// only re-display clock if the seconds
			// have changed OR if admin-forced was 'true'
			ShowTime(1);
		}	// seconds value changed
	}	// time-set menu screen
#endif // USE_DS1302_RTC

#ifdef USE_ANALOG_POT
	/*
	 * scan analog pot (if it's marked as 'installed') and translate
	 * its 0..1023 range to 'a..z' etc
	 */
	if (option_pot_installed == 1) {
		sensed_pot_value = read_analog_pot_with_smoothing(
			SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
		);	// to smooth it out

		// 1-5 is a good value to ignore noise
		if (abs(sensed_pot_value - last_seen_pot_value) >
			POT_CHANGE_THRESH) {
			// the setting *just* before the user touched the pot
			old_valuator = valuator;
			// save for next time
			last_seen_pot_value = sensed_pot_value;

			// which char map range do we want to map within?
			if (data_type == D_INTEGER) {
				min_legal = int_nodes[data_idx].min_legal;

				if (eeprom_index == EEPROM_VOL_MIN_LIMIT || 
				    eeprom_index == EEPROM_VOL_MAX_LIMIT) {
					max_legal = max_byte_size;
				}
				else {
					max_legal =
						int_nodes[data_idx].max_legal;
			}

				// edit the WHOLE 3-char byte field as a whole
				temp_valuator = l_map(sensed_pot_value, 
					ANALOG_POT_MIN_RANGE,
					ANALOG_POT_MAX_RANGE,
					min_legal, max_legal
				);
			}
			else if (data_type == D_STRING) {
				if (capslock == 0) {
					temp_valuator = l_map(sensed_pot_value, 
						ANALOG_POT_MIN_RANGE, 
						ANALOG_POT_MAX_RANGE,
						'a', 'z'
					);
				} 
				else if (capslock == 1) {
					temp_valuator = l_map(sensed_pot_value, 
						ANALOG_POT_MIN_RANGE, 
						ANALOG_POT_MAX_RANGE, 
						'A', 'Z'
					);
				} 
				else {  // capslock == 2
					temp_valuator = l_map(sensed_pot_value, 
						ANALOG_POT_MIN_RANGE, 
						ANALOG_POT_MAX_RANGE,
						' ', '9'
					);
				}
			}

			/*
			 * if the pot value changed during this scan, use the
			 * new value (somehow)
			 */
			if (temp_valuator != old_valuator) {
				init_blink_state();

				/*
				 * which mode are we in?  if this is an
				 * integer field, we edit the whole number,
				 * not by character.  if in a string field
				 * then each character IS what we cycle
				 * through, with the analog pot.
				 */
				if (data_type == D_INTEGER) {
					valuator_byte_update(temp_valuator);
				} 
				else if (data_type == D_STRING) {
					// not a 'special' integer

					/*
					 * change the char under the current
					 * cursor
					 */

					// save our new char
					string_buf[current_cursor_pos] = (byte) temp_valuator;

					// save our new char to EEPROM,
					// directly, right now!
					//EEPROM.write(
					//	(eeprom_index +
					//	 current_cursor_pos),
					//	(byte) temp_valuator
					//);
					menu_draw_string(0);
				}
				delay(50);	// Debounce switch
			}
		}
	}
#endif // USE_ANALOG_POT
  
	/*
	 * we got a valid IR start pulse! fetch the keycode, now.
	 */
	key = get_IR_key();
	if (key == 0) {
		return;
	}

	// go to previous 'screen'
	if (search_eeprom_for_IR_code() == IFC_VOL_DOWN_ALIAS) {
		// if there was a pending change, sync it out to EEPROM, first
		if (data_type == D_INTEGER) {
			// we don't do this for string types
			leaving_field_saving_data();
		}

		// if we were in a 'blink out' state, quickly remove the cursor
		init_blink_state();

		// find next screen to cycle to
		current_screen_node =
			screen_nodes[current_screen_node].node_next_idx;
		menu_draw_screen(current_screen_node);

		// draw our block cursor over the new position
		// and reset the timer
		toggle_blink_state();

		delay(80); // Debounce switch
	}
	// go to next 'screen'
	else if (search_eeprom_for_IR_code() == IFC_VOL_UP_ALIAS) {
		// if there was a pending change, sync it out to EEPROM, first
		if (data_type == D_INTEGER) {
			// we don't do this for string types
			leaving_field_saving_data();
		}

		// if we were in a 'blink out' state, quickly remove the cursor
		init_blink_state();

		// find next screen to cycle to
		current_screen_node =
			screen_nodes[current_screen_node].node_prev_idx;
		menu_draw_screen(current_screen_node);

		// draw our block cursor over the new position and
		// reset the timer
		toggle_blink_state();

		delay(80); // Debounce switch
	}
	// this is a toggled 'shift key' for upper- and lowercase letters
	else if (search_eeprom_for_IR_code() == IFC_MULTI_OUT) {
		// capslock only works for STRING types
		if (data_type == D_STRING) {
			// toggle our state
			if (capslock == 0) {
				// we were in lowercase
				char_edit = 'A';
				capslock = 1;
			} 
			else if (capslock == 1) {
				// we were in uppercase
				char_edit = '!';
				capslock = 2;
			} 
			else if (capslock == 2) {
				// we were in number and symbol mode
				char_edit = 'a';
				capslock = 0;	// cycle around again
			}

			string_buf[current_cursor_pos] = char_edit;

			// save our new char to EEPROM, directly, right now!
			EEPROM.write(
				(eeprom_index + current_cursor_pos), char_edit
			);
			menu_draw_string(0);

			delay(200); // Debounce switch
		}
	}
	// RESET (to defaults, from int_nodes table) the char under the cursor
	// (0 for ints and SPACE for strings)
	else if (key == ir_keypress_cache[IFC_MUTE_ONOFF]) {
		if (data_type == D_INTEGER) {
			// exception: do NOT use default value for maxvol!
			// maxvol has to be the CURRENT 'max_byte_size'
			if (eeprom_index == EEPROM_VOL_MAX_LIMIT) {
				menu_edited_byte_var = max_byte_size;
			} 
			else {
				menu_edited_byte_var =
					int_nodes[data_idx].default_value;
			}

			valuator_byte_update(menu_edited_byte_var);
		} 
		else if (data_type == D_STRING) {
			string_buf[current_cursor_pos] = ' ';

			// save our new char to EEPROM, directly, right now!
			EEPROM.write(
				(eeprom_index + current_cursor_pos),
				string_buf[current_cursor_pos]);
			menu_draw_string(0);
		}

		delay(150); // Debounce switch
	}
	// left-arrow
	else if (key == ir_keypress_cache[IFC_VOL_DOWN_SLOW]) {
		// if we were in a 'blink out' state, quickly remove the cursor
		init_blink_state();

		/*
		 * byte_integer or string?
		 */
		// 0..255 size (byte), we only do ++ and -- ops on those
		if (data_type == D_INTEGER) {
			// leaving this field.  save it to EEPROM!
			leaving_field_saving_data();

			// get the prev field from EEPROM so the user
			// can see/edit that one.
			// always updates:
			// current_cursor_pos, current_menu_node
			menu_find_prev_data_field();

			recache_data_index_and_type();

			//  always updates: current_cursor_pos
			if (data_type == D_INTEGER) {
				menu_find_start_of_word();

				// refresh screen/field from EEPROM
				menu_draw_int(blink_state);
			} 
			else if (data_type == D_STRING) {
				menu_find_end_of_word();
			 
				// refresh screen/field from EEPROM
				menu_draw_string(blink_state);
			}
		}
		else if (data_type == D_STRING) {
			// action when user hits left-arrow
			if (current_cursor_pos > 0) {
				// still in the same field
				current_cursor_pos--;
			} 
			else {
				menu_find_prev_data_field();

				recache_data_index_and_type();

				if (data_type == D_INTEGER) {
					menu_find_start_of_word();

					// refresh screen/field from EEPROM
					menu_draw_int(blink_state);
				} 
				else if (data_type == D_STRING) {
					menu_find_end_of_word();

					// refresh screen/field from EEPROM
					menu_draw_string(blink_state);
				}
			}
		} // string

		// draw our block cursor over the new position and reset
		// the timer
		toggle_blink_state();
    
		delay(120); // Debounce switch
	}
	// right-arrow
	else if (key == ir_keypress_cache[IFC_VOL_UP_SLOW]) {
		// if we were in a 'blink out' state, quickly remove the cursor
		init_blink_state();

		/*
		 * byte_integer or string?
		 */
		// 0..255 size (byte), we only do ++ and -- ops on those
		if (data_type == D_INTEGER) {
			// leaving this field.  save it to EEPROM!
			leaving_field_saving_data();

			menu_find_next_data_field();

			recache_data_index_and_type();

			if (data_type == D_INTEGER) {
				menu_find_start_of_word();

				// refresh screen/field from EEPROM
				menu_draw_int(blink_state);
			} 
			else if (data_type == D_STRING) {
				menu_find_start_of_word();

				// refresh screen/field from EEPROM
				menu_draw_string(blink_state);
			}
		}
		else if (data_type == D_STRING) {
			// action when user hits right-arrow
			if (current_cursor_pos < menu_find_data_len()-1) {
				// still in the same field
				current_cursor_pos++;
			} 
			else {
				menu_find_next_data_field();

				recache_data_index_and_type();

				if (data_type == D_INTEGER) {
					menu_find_start_of_word();

					// refresh screen/field from EEPROM
					menu_draw_int(blink_state);
				} 
				else if (data_type == D_STRING) {
					menu_find_start_of_word();

					// refresh screen/field from EEPROM
					menu_draw_string(blink_state);
				}
			}
		}
		// draw our block cursor over the new position and
		// reset the timer
		toggle_blink_state();

		delay(120); // Debounce switch
	}
	// down-arrow
	else if (key == ir_keypress_cache[IFC_VOL_DOWN_FAST]) {
		init_blink_state();

		if (data_type == D_INTEGER) {
			if (menu_edited_byte_var >
				int_nodes[data_idx].min_legal) {
				--menu_edited_byte_var;
			}

			valuator_byte_update(menu_edited_byte_var);
		}
		else if (data_type == D_STRING) {
			// current char under cursor
			char_edit = string_buf[current_cursor_pos];

			// if we are a string, get the current char
			// under the cursor and rotate it DOWN
			// (with wrap-around)
			--char_edit;

			// underflow our ascii table?
			if (char_edit < ' ') {
				// last valid ascii char (for us)
				char_edit = '}';
			} 
			else if (char_edit > '}') {
				char_edit = ' ';
			}

			// save our new char
			string_buf[current_cursor_pos] = char_edit;

			// save our new char to EEPROM, directly, right now!
			EEPROM.write(
				(eeprom_index + current_cursor_pos),
				string_buf[current_cursor_pos]
			);

			menu_draw_string(0);
		}

		delay(40); // Debounce switch
	}
	// up-arrow
	else if (key == ir_keypress_cache[IFC_VOL_UP_FAST]) {
		init_blink_state();

		if (data_type == D_INTEGER) {
			++menu_edited_byte_var;
      
			valuator_byte_update(menu_edited_byte_var);
		}
		else if (data_type == D_STRING) {
			// current char under cursor
			char_edit = string_buf[current_cursor_pos];

			// if we are a string, get the current char under
			// the cursor and rotate it UP (with wrap-around)
			++char_edit;

			// underflow our ascii table?
			if (char_edit > '}') {
				// first valid ascii char (for us)
				char_edit = ' ';
			} 
			else if (char_edit < ' ') {
				char_edit = '}';
			}

			// save our new char
			string_buf[current_cursor_pos] = char_edit;

			// save our new char to EEPROM, directly, right now!
			EEPROM.write(
				(eeprom_index + current_cursor_pos),
				string_buf[current_cursor_pos]
			);

			menu_draw_string(0);
		}

		delay(40); // Debounce switch
	}
	/*
	 * exit this mode
	 */
	else if (search_eeprom_for_IR_code() == IFC_MENU) {
		// leaving this field.  save it to EEPROM!
		if (data_type == D_INTEGER) {
			leaving_field_saving_data();
		}

		// we're done in this edit mode
		toplevel_mode = TOPLEVEL_MODE_NORMAL;

		// save last-used positions to EEPROM so we can
		// quickly re-enter to edit
		//EEPROM.write(EEPROM_MENU_PGNUM,   current_screen_node);
		//EEPROM.write(EEPROM_MENU_NODENUM, current_menu_node);

#ifdef USE_MOTOR_POT
		// zoom over to the last volume level (resync our knob)
		if (option_motor_pot_installed == 1) {
			pot_state = MOTOR_IN_MOTION;
			last_seen_pot_value = -1;
		}
#endif
		/*
		 * redraw the screen in '0' (main) mode
		 */
		lcd.clear();
		lcd.set_backlight(lcd.backlight_max);

#ifdef USE_BIGFONTS
		if (big_mode == 1) {
			lcd.cgram_load_big_numeral_fonts();
			// redraw, but in big numerals
			update_volume(volume, 0);

		}
		else {
			common_startup(1);
		}
#else
		common_startup(1);
#endif

		delay(500); // Debounce switch
	}

	irrecv.resume();	// we just consumed one key;
				// 'start' to receive next
}


#ifdef USE_SERIAL_UART
/*
 * for possible future expansion.  if it works, it will allow remote
 * 'management' access to this device.
 */

void
handle_any_serial_TTY_io(void)
{
  byte  ch;
  int the_addr;

  if (Serial.available()) {
    ch = Serial.read();

    // check for our sync or 'start' char
    if (ch == '#') {
      uart_buffer_idx = 0;  // reset (start of packet)
      return;
    }

    // 'end of line' 
    if (ch == 10 || ch == 13) {
      if (uart_buffer_idx < SERIAL_UART_BUF_LEN)
        serial_uart_buffer[uart_buffer_idx] = '\0';
      else
        serial_uart_buffer[SERIAL_UART_BUF_LEN] = '\0';

      // '?' means GET data
      if (serial_uart_buffer[0] == '?') {
        the_addr = atoi(&(serial_uart_buffer[1]));
        ee_val = EEPROM.read(the_addr);

        // sprintf(serial_uart_buffer,
        //     "@%03d = %03d\n",
        //     the_addr, ee_val);
        sprintf(serial_uart_buffer, "%d", ee_val);
        // print entire saved string
        Serial.println(serial_uart_buffer);
      } 

      // see if it was a 'get string' request or 'set string'
      // (string is 8 bytes printable ascii, fixed)

      if (serial_uart_buffer[0] == '$') {
        // get the addr
        strncpy(four_byte_buffer,
          &(serial_uart_buffer[1]), 3);
        four_byte_buffer[3]='\0';
        the_addr = atoi(four_byte_buffer);

        // was this a GET or SET?
        // a SET has an '=' at offset 4

        // SET
        // example:
        // arduino-serial -b 57600 -p /dev/ttyUSB0
        // -d 20 -s '#$003=[abcd1234]' -d 20 -r
        if (serial_uart_buffer[4] == '=') {
          // copy the value
          strncpy(string_buf,
            &(serial_uart_buffer[6]),
            LEN_PORTNAME_STRING);
          string_buf[LEN_PORTNAME_STRING]='\0';

          eeprom_write_8_bytes(the_addr);
        }
        // GET
        else {
          eeprom_read_8_bytes(the_addr);

          // sprintf(serial_uart_buffer,
          //     "$%03d = [", the_addr);
          // print entire saved string
          // Serial.print(serial_uart_buffer);
          // Serial.print("\"");
          // Serial.print("[");
          // print entire saved string
          Serial.println(string_buf);
          // Serial.println("]");
          // Serial.println("\"");
        }
      }
      // see if it was a SET ('%');
      // if so, parse out the addr,value
      else if (serial_uart_buffer[0] == '%') {
        // addr
        strncpy(four_byte_buffer,
          &(serial_uart_buffer[1]), 3);
        four_byte_buffer[3]='\0';
        ee_addr = atoi(four_byte_buffer);

        // value
        strncpy(four_byte_buffer,
          &(serial_uart_buffer[5]), 3);
        four_byte_buffer[3]='\0';
        ee_val = atoi(four_byte_buffer);

#ifdef ECHO_BACK_THE_CMD
        sprintf(serial_uart_buffer,
          "%03d = ", ee_addr);
        // print entire saved string
        Serial.print(serial_uart_buffer);

        if (ee_val < ' ')
          sprintf(serial_uart_buffer,
            "%03d x %x", ee_val, ee_val);
        else
          sprintf(serial_uart_buffer,
            "%03d c %c", ee_val, ee_val);

        // print entire saved string
        Serial.println(serial_uart_buffer);
#endif

        //
        // which variable do we want to get or set
        //
        if (ee_addr == EEPROM_VOL_CMD) {
          // quick commands for the 4 speeds of
          // volume up/down
          switch (ee_val) {
          case VOL_CMD_UP_SLOW:
            vol_change_relative(
              VC_UP, VC_SLOW
            );
            // serial_return_value(volume);
            sprintf(serial_uart_buffer,
              "%03d", volume);
            // print entire saved string
            Serial.println(
              serial_uart_buffer
            );
            delayMicroseconds(500);
            break;
          case VOL_CMD_UP_FAST:
            vol_change_relative(
              VC_UP, VC_FAST
            );
            // serial_return_value(volume);
            sprintf(serial_uart_buffer,
              "%03d", volume);
            // print entire saved string
            Serial.println(
              serial_uart_buffer
            );
            delayMicroseconds(500);
            break;
          case VOL_CMD_DOWN_SLOW:
            vol_change_relative(
              VC_DOWN, VC_SLOW
            );
            // serial_return_value(volume);
            sprintf(serial_uart_buffer,
              "%03d", volume);
            // print entire saved string
            Serial.println(
              serial_uart_buffer\
            );
            delayMicroseconds(500);
            break;
          case VOL_CMD_DOWN_FAST:
            vol_change_relative(
              VC_DOWN, VC_FAST
            );
            // serial_return_value(volume);
            sprintf(serial_uart_buffer,
              "%03d", volume);
            // print entire saved string
            Serial.println(
              serial_uart_buffer
            );
            delayMicroseconds(500);
            break;
          }
        }
        else if (ee_addr == EEPROM_VOLUME) {
          // 'virtual volume'
          volume = ee_val;
          update_volume(volume, 0);
          // serial_return_value(volume);
          sprintf(serial_uart_buffer,
            "%03d", volume);
          // print entire saved string
          Serial.println(serial_uart_buffer);
        }
        else if (ee_addr == EEPROM_POWER) { 
          // on/off
          power = ee_val;
          //EEPROM.write(EEPROM_POWER, power);

          if (power == POWER_ON) {
            power_on_logic(1);
            change_input_selector(
              input_selector
            );
            resync_display_mode();
            common_startup(1);
            sprintf(serial_uart_buffer,
              "%03d", power);
            // print entire saved string
            Serial.println(
              serial_uart_buffer
            );
          }
          else if (power == POWER_OFF) {
            power_off_logic();
          }
        }
        // input sel
        else if (ee_addr == EEPROM_INPUT_SEL) {
          input_selector = ee_val;
          change_input_selector(input_selector);
          common_startup(1);
          sprintf(serial_uart_buffer,
            "%03d", input_selector);
          // print entire saved string
          Serial.println(serial_uart_buffer);
        }
        else {
          // set the eeprom value directly,
          // no side-effects
          EEPROM.write(ee_addr, ee_val);
          recalc_volume_range();
          // in case the user changed something
          // that others depend on

          sprintf(serial_uart_buffer,
            "%03d", ee_val);
          // print entire saved string
          Serial.println(serial_uart_buffer);
        }
      } // SET

      uart_buffer_idx = 0;
      return;
    }

    // put char in buffer and incr our buf_len
    if (uart_buffer_idx < SERIAL_UART_BUF_LEN) {
      serial_uart_buffer[uart_buffer_idx] = ch;
      uart_buffer_idx++;
      return;
    }
      
  }
}
#endif // USE_SERIAL_UART
