/*
 *  @(#)lcd1_libs.h	1.15 16/01/04
 *
 *  lcd1_libs.h: misc drivers and common libs header file
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

#ifndef _LCD1_LIBS_H_
#define _LCD1_LIBS_H_

/*
 * IRremote
 * Version 0.1 July, 2009
 * Copyright 2009 Ken Shirriff
 * http://arcfn.com
 *
 * Interrupt code based on NECIRrcv by Joe Knapp
 * http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?num=1210243556
 * Also influenced by http://zovirl.com/2008/11/12/building-a-universal-remote-with-an-arduino/
 */

// mutex flag: we are not allowed to 'do anything' if the
// LCD is currently in use
extern uint8_t	lcd_in_use_flag;


#define CLKFUDGE			5	// fudge factor for clock
						// interrupt overhead
#define CLK				256	// max value for clock
						// (timer 2)
#define PRESCALE			8	// timer2 clock prescale
#define SYSCLOCK			16000000 // main Arduino clock

// timer clocks per microsecond
#define CLKSPERUSEC			(SYSCLOCK / PRESCALE / 1000000)

#define ERR				0
#define DECODED				1

#define BLINKLED			13

#define RAWBUF				76	// Length of raw duration
						// buffer

// defines for setting and clearing register bits
#ifndef cbi
#define cbi(sfr, bit)			(_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit)			(_SFR_BYTE(sfr) |= _BV(bit))
#endif

// clock timer reset value
#define INIT_TIMER_COUNT2		(CLK - USECPERTICK*CLKSPERUSEC + CLKFUDGE)
#define RESET_TIMER2			(TCNT2 = INIT_TIMER_COUNT2)

// pulse parameters in usec
#define NEC_HDR_MARK			9000
#define NEC_HDR_SPACE			4500
#define NEC_BIT_MARK			560
#define NEC_ONE_SPACE			1600
#define NEC_ZERO_SPACE			560
#define NEC_RPT_SPACE			2250

#define SONY_HDR_MARK			2400
#define SONY_HDR_SPACE			600
#define SONY_ONE_MARK			1200
#define SONY_ZERO_MARK			600
#define SONY_RPT_LENGTH			45000

#define RC5_T1				889
#define RC5_RPT_LENGTH			46000

#define RC6_HDR_MARK			2666
#define RC6_HDR_SPACE			889
#define RC6_T1				444
#define RC6_RPT_LENGTH			46000

#ifdef USE_FP_MATH
#define TOLERANCE			25	// percent tolerance
						// in measurements
#define LTOL				(1.0 - TOLERANCE/100.) 
#define UTOL				(1.0 + TOLERANCE/100.) 
#else
#define LTOL				3	// (1.0 - TOLERANCE/100.) 
#define UTOL				5	// (1.0 + TOLERANCE/100.) 
#endif  // FP_PATH


// Marks tend to be 100us too long, and spaces 100us too short
// when received. (sensor lag?)
#define MARK_EXCESS			100

#define _GAP				5000	// Minimum map between
						// transmissions
#define GAP_TICKS			(_GAP/USECPERTICK)

#ifdef USE_FP_MATH
#define TICKS_LOW(us)			(int) (((us) * (LTOL) / USECPERTICK))
#define TICKS_HIGH(us)			(int) (((us) * (UTOL) / USECPERTICK + 1))
#else
#define TICKS_LOW(us)			(int) (((us) * (LTOL) / USECPERTICK/4))
#define TICKS_HIGH(us)			(int) (((us) * (UTOL) / USECPERTICK/4 + 1))
#endif

#ifndef DEBUG
#define MATCH(measured_ticks, desired_us)	((measured_ticks) >= TICKS_LOW(desired_us) && (measured_ticks) <= TICKS_HIGH(desired_us))
#define MATCH_MARK(measured_ticks, desired_us)	MATCH((measured_ticks), (desired_us) + MARK_EXCESS)
#define MATCH_SPACE(measured_ticks, desired_us)	MATCH((measured_ticks), (desired_us) - MARK_EXCESS)
// Debugging versions are in IRremote.cpp
#endif

// receiver states
#define STATE_IDLE			2
#define STATE_MARK			3
#define STATE_SPACE			4
#define STATE_STOP			5

// information for the interrupt handler
typedef struct {
	uint8_t		recvpin;	// pin for IR data from detector
	uint8_t		rcvstate;	// state machine
	uint8_t		blinkflag;	// enable blinking of pin 13
					// on IR processing
	unsigned int	timer;		// state timer, counts 50uS ticks.
	unsigned int	rawbuf[RAWBUF];	// raw data
	uint8_t		rawlen;		// counter of entries in rawbuf
} irparams_t;

// Defined in IRremote.cpp
extern volatile irparams_t	irparams;

// IR detector output is active low
#define MARK				0
#define SPACE				1

#define TOPBIT				0x80000000

#define NEC_BITS			32
#define SONY_BITS			12
#define MIN_RC5_SAMPLES			11
#define MIN_RC6_SAMPLES			1

// Results returned from the decoder
class decode_results {
public:
	char		decode_type;	// NEC, SONY, RC5, RC6, UNKNOWN
	unsigned long	value;		// Decoded value
	int		bits;		// Number of bits in decoded value
	volatile unsigned int *rawbuf;	// Raw intervals in .5 us ticks
	int		rawlen;		// Number of records in rawbuf.
};

// Values for decode_type
#define NEC				1
#define SONY				2
#define RC5				3
#define RC6				4
#define UNKNOWN				-1

// Decoded value for NEC when a repeat code is received
#define REPEAT				0xffffffff

// main class for receiving IR
class IRrecv {
public:
	IRrecv(int recvpin);
	int	decode(decode_results *results);
	void	enableIRIn(void);
	void	resume(void);

private:
	// These are called by decode
	uint8_t	getRClevel(decode_results *results, int *offset,
			   int *used, int t1);
	long	decodeSony(decode_results *results);
	long	decodeNEC(decode_results *results);
	long	decodeRC5(decode_results *results);
	long	decodeRC6(decode_results *results);
};

#ifdef SUPPORT_IRSEND
class IRsend {
public:
	IRsend(void) {}
	void	sendNEC(unsigned long data, int nbits);
	void	sendSony(unsigned long data, int nbits);
	void	sendRaw(unsigned int buf[], int len, int hz);
	void	sendRC5(unsigned long data, int nbits);
	void	sendRC6(unsigned long data, int nbits);

private:
	void	enableIROut(int khz);
	void	mark(int usec);
	void	space(int usec);
};
#endif	// SUPPORT_IRSEND

#define USECPERTICK			50	// microseconds per
						// clock interrupt tick

/*
 * LCD control via i2c
 */
// helpful position constants; lets us put our cursor at start of lines
// (or add offset, up to 16/20 chars)
#define LCD_CURS_POS_L1_HOME		0x80
#define LCD_CURS_POS_L2_HOME		0xC0
#define LCD_CURS_POS_L3_HOME		0x94
#define LCD_CURS_POS_L4_HOME		0xD4

//command bytes for LCD
#define CMD_CLR				0x01
#define CMD_RIGHT			0x1C
#define CMD_LEFT			0x18
#define CMD_HOME			0x02


/*
 * LCD bargraph drawing constants
 */

// display type0: 16x2
#define DT0_LCD_PHYS_ROWS		16
#define DT0_LCD_PHYS_LINES		2
#define DT0_CHAR_CELL_GRAPH_SIZE	7
#define DT0_PROGRESS_STEPSIZE		1

// display type2: 40x2
#define DT2_LCD_PHYS_ROWS		40
#define DT2_LCD_PHYS_LINES		2
#define DT2_CHAR_CELL_GRAPH_SIZE	30
#define DT2_PROGRESS_STEPSIZE		2

// this is based on font and does not vary at all
#define HORIZ_PIXELS_PER_CHAR		5

// these are based on which LCD size the user said we are using
extern byte		lcd_phys_rows;
extern byte		lcd_phys_lines;
extern byte		char_cell_graph_size;
extern byte		progress_stepsize;

// derived from LCD size
extern byte	total_horiz_pixels;

// backlight
#define DEFAULT_BL_LEVEL		255
#define MIN_BL_LEVEL			100

// for backlight_bright_mode
#define BACKLIGHT_MODE_FULL_DARK	1
#define BACKLIGHT_MODE_AUTO_DIM		2
#define BACKLIGHT_MODE_FULL_BRIGHT	3

// for backlight_state
#define BACKLIGHT_IS_ON			0
#define BACKLIGHT_IS_DIMMED		1
#define BACKLIGHT_IS_OFF		2

// the LCD i2c device address (hardwired on LCDuino-1)
#define LCD_MCP_DEV_ADDR		0x27

// MCP i2c PE 'user input' pins
#define LCD_MCP_INPUT_PINS_MASK		B01100000

// general MCP i2c register codes
#define MCP_REG_IODIR			0x00
#define MCP_REG_IPOL			0x01
#define MCP_REG_GPINTEN			0x02
#define MCP_REG_DEFVAL			0x03
#define MCP_REG_INTCON			0x04
#define MCP_REG_IOCON			0x05
#define MCP_REG_GPPU			0x06
#define MCP_REG_INTF			0x07
#define MCP_REG_INTCAP			0x08
#define MCP_REG_GPIO			0x09
#define MCP_REG_OLAT			0x0A

// enums for display type: lcd or vfd
#define DISP_TYPE_LCD			1
#define DISP_TYPE_VFD			2

// we use our own 
#define LOCAL_MCP_DRIVER		1

/*
 * lcd enums for calling clear_line() class.  this avoids direct coding
 * of literals and you don't have to know if it's zero or one-based, etc.
 */
#define LCD_LINE_ONE			1
#define LCD_LINE_TWO			2


// Raw i2c read/write functions using the Wire library.
// Must first call Wire.begin() before use.
extern byte	i2c_read(byte i2c_addr, byte reg, byte *ret);
extern byte	i2c_write(byte i2c_addr, byte reg, byte val);


// IMPORTANT! Wire. must have a begin() before calling init()

class LCDI2C4Bit {
public:
	LCDI2C4Bit(byte devI2CAddress, byte num_lines, byte lcdwidth,
		   byte backlightPin);
	void	init(void);
	void	command(byte);
	void	write(byte);
	void	print(char value[]);
	void	clear(void);
	void	clear_line(byte);
	void	set_backlight(byte);
	void	SendToLCD(byte);
	void	WriteLCDByte(byte);
#ifdef LOCAL_MCP_DRIVER
	void	SetMCPReg(byte, byte);
	byte	GetMCPReg(byte);
#endif
	void	cursorTo(byte, byte);
	void	SetInputKeysMask(byte);
	byte	ReadInputKeys(void);
	void	cgram_load_normal_bargraph(void);
#ifdef USE_BIGFONTS
	void	cgram_load_big_numeral_fonts(void);
	void	draw_bignum_numeral_at(byte val, byte char_pos);
	void	draw_big_numeral_db_chars(char *string_buf);
#endif
	void	send_string(const char *str, const byte addr);
	void	send_string_P(const char* PROGMEM str, byte addr);

	// display and backlight routines
	void	turn_display_on(void);
	void	turn_display_off(void);
	void	fade_backlight_complete_off(void);
	void	fade_backlight_off(void);
	void	restore_backlight(void);
	void	fade_backlight_on(void);
	void	handle_backlight_auto(void);

	// a bargraph that we use a lot
	void	draw_graphic_bar(char *dest_buf, int value,
				 int total_bargraph_size);

	//byte	display_type;  // = DISP_TYPE_LCD;

	unsigned long	one_second_counter_ts;
	int	seconds;
	byte	backlight_admin;	// administratively set
					// (enable auto timeout; normal mode)
	byte	backlight_state;

	byte	backlight_min;		// minimum backlight intensity
	byte	backlight_max;		// maximum backlight intensity

	//note: defined above; shown here for clarity
	//#define BACKLIGHT_MODE_FULL_DARK    1
	//#define BACKLIGHT_MODE_AUTO_DIM     2
	//#define BACKLIGHT_MODE_FULL_BRIGHT  3
	byte	backlight_bright_mode;	/* = BACKLIGHT_MODE_FULL_BRIGHT; */
  
private:
	byte	lcd_i2c_address;
	byte	myNumLines;
	byte	myWidth;
	byte	myBacklightPin;
	byte	dataPlusMask;
	byte	myInputKeysMask;
};

extern LCDI2C4Bit	lcd;

extern void		display_progmem_string_to_lcd_P(
				const char* const PROGMEM p_ptr[],
				const byte addr);
extern void		lcd_clear_8_chars(byte column);
extern void		lcd_draw_big_dash_char(byte column);

#ifdef USE_PGA_I2C

// You will have to change the address for the PCF8574A to B0111000
// (with all three address pins tied to ground). The Wire library will
// take care of the last bit (the R/W) so make sure you leave that
//  out of the address.  Note that the R/W bit is not part of this address.

//#define I2C_PGA_PE_ADDR	B0111111	// PCF8574A  with three address
						// pins tied to Vcc!
//#define I2C_PGA_PE_ADDR	B0100000	// Address with three address
						// pins grounded.

// mute wire
#define PGA_I2C_MUTE_HIGH	B00100000
#define PGA_I2C_MUTE_LOW	B00000000

// chip-select wire
#define PGA_I2C_CS		B00011100
#define PGA_I2C_CS_HI		B00011100
#define PGA_I2C_CS_LOW		B00000000

// data wire
#define PGA_I2C_SDATA		B00000010
#define PGA_I2C_SDATA_HI	B00000010
#define PGA_I2C_SDATA_LOW	B00000000

// clock wire
#define PGA_I2C_SCK		B00000001
#define PGA_I2C_SCK_HI		B00000001
#define PGA_I2C_SCK_LOW		B00000000

// public functions for PGA23xx

extern void	pga23xx_init(void);
extern void	pga23xx_write(byte out_byte);
extern void	pga2311_set_volume(byte left, byte right);

#endif //  USE_PGA_I2C


#ifdef USE_X10
/*
 * x10 stuff
 */

#ifndef X10_H
#define X10_H

// arduino pins
#define X10_RTS_PIN			10	// RTS for C17A - DB9 pin 7
#define X10_DTR_PIN			11	// DTR for C17A - DB9 pin 4

// misc constants
#define X10_BIT_DELAY			1	// ms delay between bits
						// (0.5ms min.)

#define X10_ON				0	// command for ON
#define X10_OFF				1	// command for OFF
#define X10_BRIGHT			2	// command for 20% brighten
#define X10_DIM				3	// command for 20% dim

class X10 {
public:
	X10(int dtr_pin, int rts_pin);
	void	init(void);
	void	xmitCM17A(char, unsigned char, unsigned char);

private:
	int	my_dtr_pin;
	int	my_rts_pin;
};

#endif // x10.h
#endif // USE_X10

#ifdef USE_MCP23XX
/*
 * mcp23xx PE chip stuff
 */

#ifndef MCP23XX_H
#define MCP23XX_H

// register codes
#define MCP_REG_CONF			0x05
#define MCP_REG_IO			0x00
#define MCP_REG_ODATA			0x0a


// general i2c register codes
#define MCP_REG_IODIR			0x00
#define MCP_REG_IPOL			0x01
#define MCP_REG_GPINTEN			0x02
#define MCP_REG_DEFVAL			0x03
#define MCP_REG_INTCON			0x04
#define MCP_REG_IOCON			0x05
#define MCP_REG_GPPU			0x06
#define MCP_REG_INTF			0x07
#define MCP_REG_INTCAP			0x08
#define MCP_REG_GPIO			0x09
#define MCP_REG_OLAT			0x0A

#define MC_PORTS_ALL_INPUTS_FLAG	0xFF
#define MC_PORTS_ALL_OUTPUTS_FLAG	0x00


class MCP23XX {
public:
	MCP23XX(byte devI2CAddress);
	void	init(void);
	void	set(byte reg, byte val);
	byte	get(byte reg);

private:
	byte	my_dev_addr;
};

#endif  // MCP23XX_H
#endif //  USE_MCP23XX


#ifdef USE_PCF8574
/*
 * philips PE chip stuff
 */

class PCF8574 {
public:
	PCF8574(void);
	void	write(byte i2c_addr, byte _data);

private:
	byte	io_sel_mask;
};

extern PCF8574	pcf;

#endif	// USE_PCF8574

// allow for 3*2 + 2*2 = 10, which is 3 d1 and 2 d2 boards
extern byte	delta_i2c_addr[/*10*/];

extern byte	option_delta1_board_count;
extern byte	option_delta2_board_count;


#ifdef USE_DS1302_RTC
/*
 * ds1302 stuff
 */

#ifndef DS1302_H
#define DS1302_H

#define SUPERCAP_INSTALLED		1


// DS1302 connections
//#define CE1302_PIN			4	// CE    (1302 pin-5)
//#define DAT1302_PIN			3	// i/o   (1302 pin-6)
//#define CLK1302_PIN			2	// clock (1302 pin-7)


/*
 * start of RTC (realtime clock) code
 * originally written by tom for his all-in-1 camera intervalometer
 */
// DS1302 Opcodes

#define WriteCtrl		B10001110
#define ReadSecs		B10000001
#define WriteSecs		B10000000
#define ReadMins		B10000011
#define WriteMins		B10000010
#define ReadHrs			B10000101
#define WriteHrs		B10000100
#define WriteTrickle		B10010000
#define ReadDay			B10001011
#define WriteDay		B10001010
#define ReadDate		B10000111
#define WriteDate		B10000110
#define ReadMonth		B10001001
#define WriteMonth		B10001000
#define ReadYear		B10001101
#define WriteYear		B10001100

#ifdef SUPERCAP_INSTALLED
//  Sets DS1302 trickle charger for supercap backup
//  1 diode, 2k series resistance
#define TrickleSet		B10100101	
#else
//  Sets DS1302 for no trickle charger output.  Use this for battery backup.
#define TrickleSet		B11111111
#endif  // supercap

class DS1302 {
public:
	// functs
	DS1302(void);
	void	init(void);
	void	GetTime (void);
	void	SetTime (void);

	// vars
	unsigned char	Hrs;	//  Hrs has 12/24 and AM/PM bits stripped
	unsigned char	Mins;
	unsigned char	Secs;	//  DS1302's BCD values  
};

#endif // DS1302_H
#endif	// USE_DS1302_RTC


// EEPROM

#define EEPROM_VOL_FLUSH_INTERVAL		(2*1000)	// 2 seconds

extern unsigned long	eewrite_cur_vol_ts;
extern byte		eewrite_cur_vol_dirtybit;
extern byte		eewrite_cur_vol_value;

extern void		EEwrite_cached_vol_value_write(byte volume);
extern void		eeprom_write_16_bytes(int eeprom_addr, char *p,
					      byte count);
extern void		EEwrite(int addr_val, byte data);

extern void		EEwrite_long(int p_address, unsigned long p_value);
extern unsigned long	EEread_long(int p_address);

extern void		eeprom_read_8_bytes(int eeprom_addr);
extern void		eeprom_write_8_bytes(int eeprom_addr);
extern void		eeprom_read_port_name(int port_num);
extern void		eeprom_write_port_name(int port_num);

// general utility functs
extern void		bcd2ascii(const byte val, byte *ms, byte *ls);
extern void		bin2ascii(const byte val, byte *ms, byte *ls);

extern byte		bcd2bin(const byte val);
extern byte		bin2bcd(const byte val);

extern long		l_map(long x, long in_min, long in_max,
			      long out_min, long out_max);

extern void		dec2bin(byte b, byte num_bits, char out_buf[]);
//extern byte		bin2dec(char *str_buf, int len);

extern void		blink_led13(byte on_off_flag);

extern void		ir_key_dump(void);
extern unsigned long	get_IR_key(void);
extern void		ShowTime(byte second_hand_shown);
extern void		unpack_rtc_bcd_data(void);
extern void		fmt_big_time(char *string_buf);

#ifdef USE_SERIAL_UART
extern void		handle_any_serial_TTY_io(void);
#endif

extern byte		my_hrs;
extern byte		my_mins;
extern byte		my_secs;
extern byte		pm_flag;

// a global static short-term use buffer
extern char		string_buf[];


// some C++ class refs
extern decode_results	results;
extern unsigned long	last_key_value;

#ifdef USE_DS1302_RTC
extern DS1302 rtc;
#endif

extern LCDI2C4Bit	lcd;


/*
 * memory checkers
 */

#ifdef USE_MEM_CHECKER

#ifdef __cplusplus
extern "C" {
#endif

// externs
// extern int	freeMemory(void);
extern int	availableMemory(void);

extern uint8_t	*heapptr, *stackptr;

#ifdef  __cplusplus
}
#endif

#endif // USE_MEM_CHECKER

#endif // _LCD1_LIBS_H_

