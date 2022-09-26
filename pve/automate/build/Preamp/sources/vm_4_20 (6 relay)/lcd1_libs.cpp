/*
 *  @(#)lcd1_libs.cpp	1.14 16/12/24
 *
 *  lcd1_libs.cpp: misc drivers and common libs in one .cpp file
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

#include "common.h"

/*
 * LCD control via i2c
 */
#ifdef USE_BIGFONTS
// big fonts
const byte	bignumchars1[] PROGMEM = {
	4,1,4, 1,4,32, 3,3,4, 1,3,4, 4,2,4,
	4,3,3, 4,3, 3, 1,1,4, 4,3,4, 4,3,4
};
const byte	bignumchars2[] PROGMEM = {
	4,2,4, 2,4,2,  4, 2,2, 2,2,4, 32,32,4,
	2,2,4, 4,2,4, 32,32,4, 4,2,4,  2, 2,4
};

#ifdef USE_THICKER_BIGFONT

const byte font_chars[] PROGMEM = {
	B11111, B00000, B11111, B11111, B00000,
	B11111, B00000, B11111, B11111, B00000,
	B11111, B00000, B11111, B11111, B00000,
	B00000, B00000, B00000, B11111, B00000,
	B00000, B00000, B00000, B11111, B00000,
	B00000, B11111, B11111, B11111, B01110,
	B00000, B11111, B11111, B11111, B01110,
	B00000, B11111, B11111, B11111, B01110
};

#else

const byte font_chars[] PROGMEM = {
	B11111, B00000, B11111, B11111, B00000,
	B11111, B00000, B11111, B11111, B00000,
	B00000, B00000, B00000, B11111, B00000,
	B00000, B00000, B00000, B11111, B00000,
	B00000, B00000, B00000, B11111, B00000,
	B00000, B00000, B00000, B11111, B01110,
	B00000, B11111, B11111, B11111, B01110,
	B00000, B11111, B11111, B11111, B01110
};

#endif	// USE_THICKER_BIGFONT
#endif	// USE_BIGFONTS

extern byte	lcd_in_use_flag;

const byte	graph_timer[]		PROGMEM = {
	142, 149, 149, 151, 145, 145, 142, 128
};
const byte	graph_horiz_line_pre[]	PROGMEM = {
	128, 128, 159, 159, 159, 159, 128, 128
};
const byte	graph_horiz_line_post[]	PROGMEM = {
	128, 128, 128, 149, 149, 128, 128, 128
};
const byte	graph_b1[]		PROGMEM = {
	128, 128, 144, 149, 149, 144, 128, 128
};
const byte	graph_b2[]		PROGMEM = {
	128, 128, 152, 157, 157, 152, 128, 128
};
const byte	graph_b3[]		PROGMEM = {
	128, 128, 156, 157, 157, 156, 128, 128
};
const byte	graph_b4[]		PROGMEM = {
	128, 128, 158, 159, 159, 158, 128, 128
};
const byte	graph_b5[]		PROGMEM = {
	128, 128, 159, 159, 159, 159, 128, 128
};


// these are based on which LCD size the user said we are using
byte		lcd_phys_rows        = DT0_LCD_PHYS_ROWS;
byte		lcd_phys_lines       = DT0_LCD_PHYS_LINES;
byte		char_cell_graph_size = DT0_CHAR_CELL_GRAPH_SIZE;
byte		progress_stepsize    = DT0_PROGRESS_STEPSIZE;


// Raw i2c read function - read one byte from specified address and register.
// Uses Wire library -- must call Wire.begin() once before use.
byte
i2c_read(byte i2c_addr, byte reg, byte *val)
{
	byte	status = 0;

#ifndef FAKE_I2C
	Wire.beginTransmission(i2c_addr);
	Wire.write(reg);
	if ((status = Wire.endTransmission()) != 0) {
		return status;
	}

	// read 1 byte
	*val = Wire.requestFrom((byte) i2c_addr, (byte)1);
	if (Wire.available()) {
		*val = Wire.read();
	}
#endif

	return status;
}


// Raw i2c write function - write one byte to specified address and register.
// Uses Wire library -- must call Wire.begin() once before use.
byte
i2c_write(byte i2c_addr, byte reg, byte val)
{
	byte	status = 0;

#ifndef FAKE_I2C
	Wire.beginTransmission(i2c_addr);
	Wire.write(reg);
	Wire.write(val);
	status = Wire.endTransmission();
#endif

	return status;
}


// ctor
LCDI2C4Bit::LCDI2C4Bit(byte devI2CAddress, byte num_lines,
		       byte lcdwidth, byte backlightPin)
{
	myNumLines = num_lines;
	myWidth = lcdwidth;
	lcd_i2c_address = devI2CAddress;

	//display_type = DISP_TYPE_LCD;
	myBacklightPin = backlightPin;

	// backlight related things
	backlight_bright_mode = BACKLIGHT_MODE_AUTO_DIM;	// default
	backlight_state = BACKLIGHT_IS_ON;
	one_second_counter_ts = 0;
	seconds = 0;
	backlight_admin = 0;		// administratively set (enable auto
					// timeout; normal mode)

	/*
	 * if we are an lcd, we use a backlight PWM wire
	 */
	//if (display_type == DISP_TYPE_LCD) {
		pinMode(myBacklightPin, OUTPUT);      // pwm backlight
	//}
}


// our init routine
void 
LCDI2C4Bit::init(void)
{
	// set a mutex so that the IR isr won't do anything
	// while we are doing lcd i/o
	lcd_in_use_flag = 1;

	dataPlusMask = 0;  // clear our mask

	// set up the MCP port expander chip (not yet talking to
	// the lcd at this point)
	SetMCPReg(MCP_REG_IOCON, 0x0C);
	delay(50);
	SetMCPReg(MCP_REG_IODIR, myInputKeysMask);
	delay(50);
	SetMCPReg(MCP_REG_GPPU, myInputKeysMask);
	delay(50);

	SendToLCD(0x03); 
	delay(5);

	SendToLCD(0x03);
	delayMicroseconds(100);

	SendToLCD(0x03);
	delay(5);

	SendToLCD(0x02);

	WriteLCDByte(0x28);

	// display ON, no cursor, no blink
	WriteLCDByte(0x0C);
	delayMicroseconds(60);

	// clear display
	command(0x01);

	// TODO: try this for vfd's and verify the brightness bits
	// actually work
	// command(B00101010);	// last 2 bits are min brightness

	lcd_in_use_flag = 0;	// clear that mutex
				// (so that the IR isr CAN now do things)
}


void
LCDI2C4Bit::SetInputKeysMask(byte input_keys_mask)
{
	myInputKeysMask = input_keys_mask;
}


#ifdef LOCAL_MCP_DRIVER
// write one byte to LCD (via i2c)
void 
LCDI2C4Bit::SetMCPReg(byte reg, byte val)
{
	i2c_write(lcd_i2c_address, reg, val);
}


// read 1 byte from LCD (via i2c)
byte
LCDI2C4Bit::GetMCPReg(byte reg)
{
	byte	val;

	i2c_read(lcd_i2c_address, reg, &val);
	return val;
}
#endif	// LOCAL_MCP_DRIVER


// 2 extra lines on the MCP chip that we can map to soft pushbuttons
byte
LCDI2C4Bit::ReadInputKeys(void)
{
	byte	data;
	data = GetMCPReg(MCP_REG_GPIO);

	return data;
}


// lower layer routine that does the enable-bit 'wrapping' of
// a 4 bit parallel transaction
void 
LCDI2C4Bit::SendToLCD(byte data) 
{
	data |= dataPlusMask;
	SetMCPReg(MCP_REG_OLAT, data);
	delayMicroseconds(9);

	data ^= 0x80; // 'enable' bit ON on LCD
	SetMCPReg(MCP_REG_OLAT, data);
	delayMicroseconds(9);

	data ^= 0x80; // 'enable' bit OFF on LCD
	SetMCPReg(MCP_REG_OLAT, data);
	delayMicroseconds(9);
}


// higher layer interface; this takes an 8-bit data and makes 2 calls to
// send to the lcd, 4 bits at a time
void 
LCDI2C4Bit::WriteLCDByte(byte bdata)
{
	// set a mutex so that the IR isr won't do anything
	// while we are doing lcd i/o
	lcd_in_use_flag = 1;

	SendToLCD(bdata >> 4);
	delayMicroseconds(9);

	SendToLCD(bdata & 0x0F);
	delayMicroseconds(9);

	lcd_in_use_flag = 0;	// clear that mutex
				// (so that the IR isr CAN now do things)
}


// 'write' sends character data, setting RS high (the other routine, 'commands'
// sends non-char data)
void 
LCDI2C4Bit::write(byte value) 
{
	dataPlusMask |= 0x10; // RS is set
	WriteLCDByte(value);
	dataPlusMask ^= 0x10; // RS is cleared
}


// 'command' leaves RS low when it sends bytes
void 
LCDI2C4Bit::command(byte command)
{
	// RS - leave low
	WriteLCDByte(command);
	delayMicroseconds(800);
}


void 
LCDI2C4Bit::print(char value[]) 
{
	for (char *p = value; *p != 0; p++) {
		write(*p);
	}
}


int	row_offsets[] = { 0x00, 0x40, 0x14, 0x54 };


// row,col are both zero-based
void 
LCDI2C4Bit::cursorTo(byte row, byte col) 
{
	command(0x80 | (col + row_offsets[row]));
}


// 'str' MUST be null-terminated
void 
LCDI2C4Bit::send_string(const char *str, const byte addr)
{
	// Send string at addr, if addr <> 0, or cursor position  if addr == 0
	if (addr != 0) {
		command(addr); // cursor pos
	}

	print((char *)str);
} 


// 'str' MUST be null-terminated
// the _P function (here) reads from PROGMEM ptr for strings, not from RAM!
void 
LCDI2C4Bit::send_string_P(const char* PROGMEM p_ptr, const byte addr)
{
	// Send string at addr, if addr <> 0, or cursor position  if addr == 0
	if (addr != 0) {
		command(addr); // cursor pos
	}

	strncpy_P(string_buf, p_ptr, STRING_BUF_MAXLEN-1);
	string_buf[STRING_BUF_MAXLEN] = '\0';  // safety

	send_string(string_buf, 0);
} 


void
lcd_clear_8_chars(byte column)
{
	char	buf9[9];

	(void) memset(buf9, ' ', 8);
	buf9[8] = '\0';  // terminate

	lcd.send_string(buf9, column);
}


#ifdef USE_BIGFONTS

// column ranges: (0..15) for the typical 16x2 LCD
void
lcd_draw_big_dash_char(byte column)
{
	lcd.command(LCD_CURS_POS_L1_HOME+column);
	lcd.write(2);	// top half of the minus sign
	lcd.write(2);

	lcd.command(LCD_CURS_POS_L2_HOME+column);
	lcd.write(1);	// bottom half of the minus sign
	lcd.write(1);
}


void
LCDI2C4Bit::draw_big_numeral_db_chars(char *string_buf)
{
	char	db_first,
		db_second,
		db_third,
		db_fourth;

	// if in mute mode, show a -- value instead of the dB number
	if (mute == 1) {
		clear();  // clear screen

		lcd_draw_big_dash_char(0);
		lcd_draw_big_dash_char(4);
		lcd_draw_big_dash_char(8);

		if (option_db_step_size != DB_STEPSIZE_WHOLE) {
			command(LCD_CURS_POS_L2_HOME + 11);
			write(B10100001);  // decimal point
		}

		lcd_draw_big_dash_char(12);
	}
	else {
		// not mute: draw real dB numbers
		db_first = string_buf[0];
		db_second  = string_buf[1];
		db_third = string_buf[2];
		db_fourth = string_buf[3];

		if (db_first == '-')
			lcd_draw_big_dash_char(0);
		else
			draw_bignum_numeral_at(db_first, 0);

		if (db_second == '-')
			lcd_draw_big_dash_char(4);
		else
			draw_bignum_numeral_at(db_second,  4);

		if (db_third == '-')
			lcd_draw_big_dash_char(8);
		else
			draw_bignum_numeral_at(db_third, 8);

		if (option_db_step_size != DB_STEPSIZE_WHOLE) {
			command(LCD_CURS_POS_L2_HOME + 11);
			write(B10100001);	// decimal point
		}

		draw_bignum_numeral_at(db_fourth, 12);
	}

	/*
	 * last char (bottom/right) is our sleep-mode icon area
	 */

	// if in sleep mode, show the clock/timer icon.
	command(LCD_CURS_POS_L2_HOME + 15);

	if (sleep_mode == 1)
		write(0);	// timer icon
	else
		write(' ');
}


void
LCDI2C4Bit::cgram_load_big_numeral_fonts(void)
{
	byte	a;
	byte	x;
	byte	y;

	/*
	 * load special graphic chars into 'cgram'
	 */
	command(0x40);		//  start off writing to CG RAM char 0

	/*
	 * load the font set
	 */
	for (x = 0; x < 5; x++) {
		a = ((x+1) << 3) | 0x40;
		for (y = 0; y < 8; y++) {
			// write the character data to the
			// character generator ram
			command(a++);
			write(pgm_read_byte(&font_chars[y*5 + x]));
		}
	}

	command(0x80);		// reset to dram mode
}


// char_pos: 0..15 (native lcd columns)
// val: ' ' or '0'..'9'
void
LCDI2C4Bit::draw_bignum_numeral_at(byte val, byte char_pos)
{
	byte	j;

	// normally we only want 0..9 but if a ' ' comes in, simulate a space
	if (val == ' ') {
		command(LCD_CURS_POS_L1_HOME + char_pos);
		print((char *)"   ");

		// bottom half
		command(LCD_CURS_POS_L2_HOME + char_pos);
		print((char *)"   ");
	}
	else {
		val -= '0';	// convert ascii char to binary value
		val *= 3;	// groups of 3 bytes in the struct/array

		// top half of char
		command(LCD_CURS_POS_L1_HOME + char_pos);
		for (j = 0; j < 3; j++) {
			write(pgm_read_byte(&(bignumchars1[val + j])));
		}

		// bottom half
		command(LCD_CURS_POS_L2_HOME + char_pos);
		for (j = 0; j < 3; j++) {
			write(pgm_read_byte(&(bignumchars2[val + j])));
		}
	}
}
#endif	// USE_BIGFONTS


void
LCDI2C4Bit::cgram_load_normal_bargraph(void)
{
	byte	i;

	/*
	 * load special graphic chars into 'cgram'
	 */
	command(0x40);		// start off writing to CG RAM char 0

	// slot-0
	for (i = 0; i < 8; i++) {
		write(pgm_read_byte(&graph_timer[i]));	// for sleep icon
	}

	// slot-1
	for (i = 0; i < 8; i++) {
		write(pgm_read_byte(&graph_horiz_line_pre[i]));
	}

	// slot-2
	for (i = 0; i < 8; i++) {
		write(pgm_read_byte(&graph_horiz_line_post[i]));
	}

	/*
	 * 5 data point (graphic) bitmaps
	 */

	// slot-3
	for (i = 0; i < 8; i++) {
		write(pgm_read_byte(&graph_b1[i]));
	}

	// slot-4
	for (i = 0; i < 8; i++) {
		write(pgm_read_byte(&graph_b2[i]));
	}

	// slot-5
	for (i = 0; i < 8; i++) {
		write(pgm_read_byte(&graph_b3[i]));
	}

	// slot-6
	for (i = 0; i < 8; i++) {
		write(pgm_read_byte(&graph_b4[i]));
	}

	// slot-7
	for (i = 0; i < 8; i++) {
		write(pgm_read_byte(&graph_b5[i]));
	}

	command(0x80);	// reset to dram mode
}


void 
LCDI2C4Bit::clear(void) 
{
	command(CMD_CLR);
}


#define LCDI2C_SUPPORT_LINE0 1

void
LCDI2C4Bit::clear_line(byte line_num)
{
	if (line_num == 1
#ifdef LCDI2C_SUPPORT_LINE0
	    || line_num == 0
#endif
	) {
		command(LCD_CURS_POS_L1_HOME);
	}
	else if (line_num == 2) {
		command(LCD_CURS_POS_L2_HOME);
	}

	for (byte i = 0; i < lcd_phys_rows; i++) {
		write(' ');
	}
}


void
LCDI2C4Bit::turn_display_off(void)
{
	analogWrite(myBacklightPin, 0);		// zero brightness
	backlight_state = BACKLIGHT_IS_OFF;	// flag it as off now
	clear();
}


void
LCDI2C4Bit::turn_display_on(void)
{
	analogWrite(myBacklightPin, backlight_max);
}


void 
LCDI2C4Bit::set_backlight(byte value) 
{
	analogWrite(myBacklightPin, value);	// 0..255 gets us 'dark'
						// to 'very bright'
}


void
LCDI2C4Bit::fade_backlight_on(void)
{
	for (int bl = backlight_min; bl < backlight_max; bl++) {
		// restore to normal brightness again
		set_backlight(bl);
		delay(2);
	}

	backlight_state = BACKLIGHT_IS_ON;	// flag it as now on

	// reset things so we start the count-down all over
	seconds = 0;
	one_second_counter_ts = millis();
}


void
LCDI2C4Bit::fade_backlight_off(void)
{
	for (int bl = backlight_max; bl > backlight_min; bl--) {
		// temporarily turn backlight entirely off
		// (or go to its lowest setting)
		set_backlight(bl);
		delay(2);
	}

	backlight_state = BACKLIGHT_IS_DIMMED;	// flag it as now off
}


void
LCDI2C4Bit::fade_backlight_complete_off(void)
{
	for (int bl = backlight_max; bl > 0; bl--) {
		// temporarily turn backlight entirely off
		// (or go to its lowest setting)
		set_backlight(bl);
		delay(2);
	}

	backlight_state = BACKLIGHT_IS_OFF;	// flag it as now off
	clear();
}


void
LCDI2C4Bit::restore_backlight(void)
{
	/*
	 * if we got a valid IR remote command and the display was off,
	 * we better turn it on again!
	 */

	if (backlight_state != BACKLIGHT_IS_ON) {
		// restore to normal brightness again
		set_backlight(backlight_max);

		if (power == POWER_ON) {
			common_startup(1);
		}

		backlight_state = BACKLIGHT_IS_ON;
	}

	// reset things so we start the count-down all over
	seconds = 0;
	one_second_counter_ts = millis();
}


void
LCDI2C4Bit::handle_backlight_auto(void)
{
	/*
	 * backlight time-out logic
	 */
	if (backlight_state == BACKLIGHT_IS_ON) {
		if (abs(millis() - one_second_counter_ts) >= 1000) {
			seconds++;
			one_second_counter_ts = millis();  // reset ourself
		}

		if (seconds >= DISPLAY_AUTODIM_TIME) {
			if (backlight_bright_mode ==
				BACKLIGHT_MODE_FULL_DARK) {
				// this also sets 'backlight_state'
				// to BACKLIGHT_IS_OFF'
				fade_backlight_complete_off();
#ifdef USE_SPDIF
				if (option_delta2_board_count == 3) {
					// s-addr type
					// lower part of byte is the address,
					// in binary.
					// upper part of byte is a mask used to
					// light 'courtesy leds' ;)
	  
					// force the upper bits to be all 1
					// (which turns OFF our leds!)
					pcf.write(
					delta_i2c_addr[I2C_SPDIF_ADDR_SLOT],
					B11110000 | (input_selector+0));
				}
#endif // USE_SPDIF
			}
			else if (backlight_bright_mode ==
					BACKLIGHT_MODE_AUTO_DIM) {
				// this also sets 'backlight_state'
				// to BACKLIGHT_IS_DIMMED'
				fade_backlight_off();
			}
		}
	}
}


// in this integer-math-only version, value is an int from (0..100)
// total_bargraph_size is still the # of lcd char cells we
// allocate for drawing the bargraph

void 
LCDI2C4Bit::draw_graphic_bar(char *dest_buf, int value,
			     int total_bargraph_size)
{
	int	i = 0;	// really do need to set i=0 here
	byte	dest_buf_idx=0;
	int	scaled_bit_pos;
	int	scaled_char_pos;
	int	scaled_char_remainder;
	int	scaled_temp;

	// which char position gets the graph point?
	scaled_temp = total_bargraph_size * value; // 0..1600
	scaled_bit_pos = scaled_temp * HORIZ_PIXELS_PER_CHAR; // 0..8000
	scaled_char_pos = scaled_temp / 100; // 0..16
	scaled_char_remainder =
		(scaled_bit_pos / 100) -
		(scaled_char_pos * HORIZ_PIXELS_PER_CHAR);

	// (1) draw from 0 up to user 'lower limit'
	for (i = 0; i < scaled_char_pos; i++) {
		// 'full blocks' line style
		dest_buf[dest_buf_idx++] = 1;
	} 

	// (2) we're at the cell that needs the 'graphic'
	//  which graphic (0..5) should be used?
	if (i < total_bargraph_size) {
		// skipping over the first 2+1 magic chars
		dest_buf[dest_buf_idx++] = scaled_char_remainder+3;
	}

	// (3) draw postamble, if any
	for (i = scaled_char_pos+1; i < total_bargraph_size; i++) {
		// continue drawing the horiz_line, to the end, in 'small dots'
		dest_buf[dest_buf_idx++] = 2;
	}

	dest_buf[total_bargraph_size] = '\0';
}


void 
display_progmem_string_to_lcd_P(const char* const PROGMEM p_ptr[],
				const byte addr)
{
	char	*p;

	// read the addr of the first byte of the text
	p = (char *) pgm_read_word(p_ptr);

	lcd.send_string_P(p, addr);
}


#ifdef USE_PGA_I2C
/*
 * burr-brown pga volume control chip series
 */
void
pga23xx_init(void)
{
	// if this is a PGA engine
	if (option_delta1_board_count == 3) {
		pcf.write(delta_i2c_addr[I2C_PGA_ADDR_SLOT], 0x00);
	}
}


void 
pga23xx_write(byte out_byte)
{
	int	i;

	// loop thru each of the 8-bits in the byte
	for (i = 0; i < 8; i++) {
		// strobe clock
		pcf.write(delta_i2c_addr[I2C_PGA_ADDR_SLOT],
			  (PGA_I2C_CS_LOW | PGA_I2C_SCK_LOW |
			   PGA_I2C_SDATA_LOW | PGA_I2C_MUTE_HIGH));

		// send the data_bit (we look at the high order bit
		// and 'print' that to the remote device)
		if (0x80 & out_byte) {	// MSB is set
			pcf.write(delta_i2c_addr[I2C_PGA_ADDR_SLOT],
				  (PGA_I2C_CS_LOW | PGA_I2C_SCK_LOW |
				   PGA_I2C_SDATA_HI | PGA_I2C_MUTE_HIGH));
		}
		else {
			pcf.write(delta_i2c_addr[I2C_PGA_ADDR_SLOT],
				(PGA_I2C_CS_LOW | PGA_I2C_SCK_LOW |
				 PGA_I2C_SDATA_LOW | PGA_I2C_MUTE_HIGH));
		}

		// unstrobe the clock
		if (0x80 & out_byte) {	// MSB is set
			pcf.write(delta_i2c_addr[I2C_PGA_ADDR_SLOT],
				 (PGA_I2C_CS_LOW | PGA_I2C_SCK_HI |
				  PGA_I2C_SDATA_HI | PGA_I2C_MUTE_HIGH));
		}
		else {
			pcf.write(delta_i2c_addr[I2C_PGA_ADDR_SLOT],
				  (PGA_I2C_CS_LOW | PGA_I2C_SCK_HI |
				   PGA_I2C_SDATA_LOW | PGA_I2C_MUTE_HIGH));
		}

		// get the next bit  
		out_byte <<= 1;	// left-shift the byte by 1 bit
	}
}

 
// note, for typical use, we assume left==right
void 
pga2311_set_volume(byte left, byte right)
{
	// only run this routine if an actual PGA was configured in the menu
	if (option_delta1_board_count == 3) {
		// strobe chip-select
		// start from high (logical-NOT on chip-select)
		pcf.write(delta_i2c_addr[I2C_PGA_ADDR_SLOT],
			  PGA_I2C_CS_HI | PGA_I2C_MUTE_HIGH);
		// begin getting the chip's attention
		pcf.write(delta_i2c_addr[I2C_PGA_ADDR_SLOT],
			   PGA_I2C_CS_LOW | PGA_I2C_MUTE_HIGH);

		// write 2 bytes of data
		pga23xx_write(left);		// left value (0..255)
		pga23xx_write(right);		// right value (0..255)

		// unstrobe chip-select
		pcf.write(delta_i2c_addr[I2C_PGA_ADDR_SLOT],
			  PGA_I2C_CS_HI | PGA_I2C_MUTE_HIGH);
	}
}
#endif // USE_PGA_I2C


#ifdef USE_X10
/*
 * x10 stuff
 */

/* Arduino Interface to the CM17A Wireless X10 dongle. BroHogan 7/19/08
 * The CM17A gets it power and data using only the RTS, CTS, & Gnd lines.
 * A MAX232 is not req. (0/+5V work OK) If MAX232 IS used reverse
 * all HIGHs & LOWS
 * Signal      RTS DTR        Standby | '1' | Wait | '0' | Wait | '1' | Wait...
 * Reset        0   0         _____________________       _____________________
 * Logical '1'  1   0   RTS _|                     |_____|
 * Logical '0'  0   1         ________       ___________________       ________
 * Standby      1   1   DTR _|        |_____|                   |_____|
 *
 * MINIMUM time for the '1', '0' and 'Wait' states is 0.5ms.
 * At least one signal must be high to keep CM17A powered while transmitting.
 * Each xmit is 40 bits -> "Header" 16 bits,  "Data" 16 bits, "Footer" 8 bits
 * CONNECTION: RTS -> DB9 pin 7.  DTR -> DB9 pin 4. Gnd. -> DB9 pin 5.
 */
unsigned int X10_houseCode[16] = {
	0x6000,	// A
	0x7000,	// B
	0x4000,	// C
	0x5000,	// D
	0x8000,	// E
	0x9000,	// F
	0xA000,	// G
	0xB000,	// H
	0xE000,	// I
	0xF000,	// J
	0xC000,	// K
	0xD000,	// L
	0x0000,	// M
	0x1000,	// N
	0x2000,	// O
	0x3000,	// P
};

unsigned int X10_deviceCode[16] = {
	0x0000,	// 1
	0x0010,	// 2
	0x0008,	// 3
	0x0018,	// 4
	0x0040,	// 5
	0x0050,	// 6
	0x0048,	// 7
	0x0058,	// 8
	0x0400,	// 9
	0x0410,	// 10
	0x0408,	// 11
	0x0418,	// 12
	0x0440,	// 13
	0x0450,	// 14
	0x0448,	// 15
	0x0458,	// 16
};

unsigned int X10_cmndCode[] = {
	0x0000,	// ON
	0x0020,	// OFF
	0x0088,	// 20% BRIGHT (0x00A8=5%)
	0x0098,	// 20% DIM    (0x00B8=5%)
};


X10::X10(int passed_dtr_pin, int passed_rts_pin) 
{
	my_dtr_pin = passed_dtr_pin;
	my_rts_pin = passed_rts_pin;
}


void
X10::init(void)
{
	pinMode(my_rts_pin, OUTPUT);	// RTS -> DB9 pin 7
	pinMode(my_dtr_pin, OUTPUT);	// DTR -> DB9 pin 4
}


void 
X10::xmitCM17A(char house, unsigned char device, unsigned char cmnd)
{
	unsigned int	dataBuff = 0;
	unsigned char	messageBuff[5];

	// Build Message by ORing the parts together.
	// No device if Bright or Dim
	if (cmnd == X10_ON | cmnd == X10_OFF) {
		dataBuff = (X10_houseCode[house-'A'] |
			    X10_deviceCode[device-1] |
			    X10_cmndCode[cmnd]);
	}
	else {
		dataBuff = X10_houseCode[house-'A'] | X10_cmndCode[cmnd];
	}

	// Build a string for the whole message . . .
	messageBuff[0] = 0xD5;               // Header byte 0 11010101 = 0xD5 
	messageBuff[1] = 0xAA;               // Header byte 1 10101010 = 0xAA 
	messageBuff[2] = dataBuff >> 8;      // MSB of dataBuff
	messageBuff[3] = dataBuff & 0xFF;    // LSB of dataBuff
	messageBuff[4] = 0xAD;               // Footer byte 10101101 = 0xAD

	// Now send it out to CM17A . . .
	digitalWrite(my_dtr_pin, LOW);	     // reset device -
					     // both low is power off
	digitalWrite(my_rts_pin, LOW);
	delay(X10_BIT_DELAY);

	digitalWrite(my_dtr_pin, HIGH);	     // standby mode - supply power
	digitalWrite(my_rts_pin, HIGH);
	delay(35);                           // extra time for it to settle

	for (unsigned char i = 0; i < 5; i++) {
		for (unsigned char mask = 0x80; mask; mask >>= 1) {
			if (mask & messageBuff[i]) 
				// 1 = RTS HIGH/DTR-LOW
				digitalWrite(my_dtr_pin, LOW);
			else 
				// 0 = DTR-HIGH/RTS-LOW
				digitalWrite(my_rts_pin, LOW);

			// delay between bits
			delay(X10_BIT_DELAY);

			// wait state between bits
			digitalWrite(my_dtr_pin, HIGH);
			digitalWrite(my_rts_pin, HIGH);
			delay(X10_BIT_DELAY);
		}
	}
	delay(1000);	// wait required before next xmit
}


void
X10_turn_power_off(void) 
{
	x10.xmitCM17A('E', 1, X10_OFF);
}


void
X10_turn_power_on(void) 
{
	x10.xmitCM17A('E', 1, X10_ON);
}
#endif  // USE_X10


#ifdef USE_MCP23XX
/*
 * mcp23xx PE chip stuff
 */

// ctor
MCP23XX::MCP23XX(byte passed_i2c_addr)
{
	my_dev_addr = passed_i2c_addr;
}


void
MCP23XX::init(void)
{
#ifndef FAKE_I2C
	set(MCP_REG_IOCON, 0x0C);
	delay(5);

	// IOREG (0x00 = 'all are output ports'
	set(MCP_REG_IODIR, MC_PORTS_ALL_OUTPUTS_FLAG);
	delay(5);
#endif
}


void
MCP23XX::set(byte reg, byte val)
{
	i2c_write(my_dev_addr, reg, val);
}


byte
MCP23XX::get(byte reg) 
{
	byte	val;

	i2c_read(my_dev_addr, reg, &val);
	return val;
}
#endif	// USE_MCP23XX


#ifdef USE_PCF8574
/*
 * philips/nxp/ti 8574(a) PE chip stuff
 */

// ctor (does nothing)
PCF8574::PCF8574(void)
{
}


void 
PCF8574::write(byte i2c_addr, byte _data) 
{
	i2c_write(i2c_addr, 0, _data);
}
#endif	// USE_PCF8574


#ifdef USE_DS1302_RTC
/*
 * DS1302 stuff
 */

void		send1302cmd(unsigned char cmd1, unsigned char cmd2);
unsigned char	get1302data(unsigned char cmd);
void		ds1302_init(void);
unsigned char	shiftin(void);


// ctor (does nothing; init() does all the work)
DS1302::DS1302 (void) 
{
}


// init the DS1302 realtime clock chip
void 
DS1302::init(void) 
{
	/*
	 * set up RTC (realtime hardware chip-based clock)
	 */
	pinMode(CE1302_PIN,  OUTPUT);
	pinMode(DAT1302_PIN, OUTPUT);
	pinMode(CLK1302_PIN, OUTPUT);

	// This routine is, most likely, called with the DS1302 running on the 
	// supercap or battery backup, so it is important to preserve its 
	// time values.

	send1302cmd(WriteCtrl, 0);	// Clear write protect

	Secs = get1302data(ReadSecs);	// Clear CH bit, preserving secs reg
	Secs &= B01111111;
	send1302cmd(WriteSecs, Secs);

	// begin charging the supercap  
	send1302cmd(WriteTrickle, TrickleSet);
}


// retrieve time from DS1302 chip
void 
DS1302::GetTime(void)
{
	Secs = get1302data(ReadSecs);
	Mins = get1302data(ReadMins);
	Hrs  = get1302data(ReadHrs);

	unpack_rtc_bcd_data();	// copies bcd stuff into binary my_hrs (etc)
}


// write time to DS1302 chip
void 
DS1302::SetTime(void)
{
	send1302cmd(WriteHrs,  Hrs);
	send1302cmd(WriteMins, Mins);
	send1302cmd(WriteSecs, Secs);
}


void 
send1302cmd(unsigned char cmd1, unsigned char cmd2)
{	
	digitalWrite(CE1302_PIN, 1);	// Set CE1302 high
	delayMicroseconds(2);

	shiftOut(DAT1302_PIN, CLK1302_PIN, LSBFIRST, cmd1); 
	delayMicroseconds(2);		// This delay might not be needed

	shiftOut(DAT1302_PIN, CLK1302_PIN, LSBFIRST, cmd2);
	digitalWrite(CE1302_PIN, 0);	// Set CE1302 low
}


unsigned char 
get1302data(unsigned char cmd)
{
	unsigned char	dat;

	digitalWrite(CE1302_PIN, 1);	// CE1302 high

	shiftOut(DAT1302_PIN, CLK1302_PIN, LSBFIRST, cmd);
	dat = shiftin();

	digitalWrite(CE1302_PIN, 0);	//  CE1302 low

	return (dat);
}


//  Shifts in a byte from the DS1302.  
//  This routine is called immediately after a shiftout.  The first bit is 
//  present on DAT1302 at call, so only 7 additional clock pulses are 
//  required.
//  Restores DAT1302 to OUTPUT prior to return.

unsigned char 
shiftin(void)
{
	unsigned char	dat = 0;
	int		i = 0;

	pinMode(DAT1302_PIN, INPUT);	// Set DAT1302 as input

	for (i = 0; i < 7; i++) {  
		if (digitalRead(DAT1302_PIN) == 1) {
			// we found a 1-bit, so add it to our collection ;)
			dat |= B10000000;
		}

		// shift over so that we can logical-OR the next 1-bit (if any)
		dat >>= 1;

		// Strobe in next data bit using CLK1302
		digitalWrite(CLK1302_PIN, 1);
		delay(1);

		digitalWrite(CLK1302_PIN, 0);
		delay(1);
	}

	pinMode(DAT1302_PIN, OUTPUT);	// Restore DAT1302 as output
	return dat;
}  
#endif // USE_DS1302_RTC


/*
 * conversion routines (bcd, ascii, etc)
 */
void 
bcd2ascii(const byte val, byte *ms, byte *ls)
{
	*ms = (val >> 4)   + '0';
	*ls = (val & 0x0f) + '0';
}


void
bin2ascii(const byte val, byte *ms, byte *ls)
{
	*ms = val / 10 + '0';
	*ls = val % 10 + '0';
}  


byte 
bcd2bin(const byte val)
{
	return (((val >> 4) * 10) + (val & 0x0f));
}


byte 
bin2bcd(const byte val)
{
	return ((val / 10 * 16) + (val % 10));
}  


// converts the 0..255 byte value 'b' into a printable ascii string '01101...'
// write string results in our SUPPLIED buffer and term with null byte.
// the result field should be 'num_bits' long in ascii chars.
void 
dec2bin(byte b, byte num_bits, char string_buf[])
{
	int	i;

	// for a normal 8-bit byte, num_bits s/b 8
	// (and so the high bit is bit7)
	for (i = 0; i < num_bits; i++) {
		if (b & 0x01)
			string_buf[num_bits-i-1] = '1';
		else
			string_buf[num_bits-i-1] = '0';

		// shift our whole byte to the right.
		// 0's are auto-inserted to the left.
		// we want to do all our compares on the
		// bit-0 position so right-shifting
		// is how we get access to each of the 8 bits.
		b >>= 1;
	}

	string_buf[num_bits] = '\0';
}


// converts the string '0101...' to a byte value 0..255
// takes string from our global buffer, string_buf[]
// returns value directly.
byte 
bin2dec(char *str_buf, int len)
{
	byte	i;
	byte	single_bit;
	byte	sum; 

	sum = 0;
	for (i = 0; i < len; i++) {
		// get the next char from the string array
		single_bit = str_buf[i];

		// if it's a '1' then add in the right power of 2
		if (single_bit == '1') {
			sum += (1 << (len - 1 - i));
		}
	}

	return sum;
}


// this fixes a bug in the arduino supplied map function.
// you would almost never reach the very 'top' of the range
// with the old functions.  this would make it very hard to
// turn the volume pot all the way up, for example.
long 
l_map(long x, long in_min, long in_max, long out_min, long out_max)
{
	return (x - in_min) * (out_max - out_min + 1) /
	       (in_max - in_min + 1) + out_min;
} 


#ifdef APP_BLINK_ON_LED13
void
blink_led13(byte on_off_flag)
{
	if (on_off_flag == 1)
		PORTB |= ((byte) B00100000);	// turn pin 13 LED on
	else
		PORTB &= ((byte) B11011111);	// turn pin 13 LED off
}
#endif


/******************
 * EEPROM routines
 ******************/

// copy 8 bytes from 'eeprom_start_addr' into global 'string_buf[]'
void
eeprom_read_8_bytes(int eeprom_start_addr)
{
	byte	sb;
	char	ch;

	// fill string_buf[] with spaces
	pad_string_buf_with_spaces(8);
	string_buf[8] = '\0';  // safety

	// copy just the string name out
	for (sb = 0; sb < 8; sb++) {
		ch = EEPROM.read(eeprom_start_addr + sb);
		if (ch == '\0') {
			// if we find a zero byte, bail out early
			// (leaving existing byte in string, untouched!)
			break;
		}
		string_buf[sb] = ch;
	}
}


// copy string (8 chars, null at [8]) from global 'string_buf' to real EEPROM
void
eeprom_write_8_bytes(int eeprom_start_addr)
{
	byte	sb;

	// copy from RAM to EEPROM
	for (sb = 0; sb < 8; sb++) {
		EEPROM.write(eeprom_start_addr+sb, string_buf[sb]);
	}
}


// this routine takes a FLASH addr (p) and a count and copies that to EEPROM
void
eeprom_write_16_bytes(int eeprom_addr, char *p, byte count)
{
	byte	c;
	byte	i;

	for (i = 0; i < count; i++) {
		c = pgm_read_byte(p++);
		EEPROM.write(eeprom_addr+i, c);
	}
}


/*
 * port names by port_num range=[0..MAX_IOPORTS-1]
 */

// copy port name string (8 chars, null at [8]) from global
// 'string_buf' to real EEPROM port_num range: 0..MAX_IOPORTS-1
void
eeprom_read_port_name(int port_num)
{
	eeprom_read_8_bytes(EEPROM_PORTS_TABLE_BASE + (port_num * 8));
}


// copy port name string to EEPROM (passing 0..MAX_IOPORTS-1 as port_num)
void
eeprom_write_port_name(int port_num)
{
	eeprom_write_8_bytes(EEPROM_PORTS_TABLE_BASE + (port_num * 8));
}


void
EEwrite_long(int p_address, unsigned long p_value)
{
	byte	byte1 = ((p_value >>  0) & 0xFF);
	byte	byte2 = ((p_value >>  8) & 0xFF);
	byte	byte3 = ((p_value >> 16) & 0xFF);
	byte	byte4 = ((p_value >> 24) & 0xFF);

	EEPROM.write(p_address,     byte1);
	EEPROM.write(p_address + 1, byte2);
	EEPROM.write(p_address + 2, byte3);
	EEPROM.write(p_address + 3, byte4);
}


unsigned long
EEread_long(int p_address)
{
	byte		byte1 = EEPROM.read(p_address);
	byte		byte2 = EEPROM.read(p_address + 1);
	byte		byte3 = EEPROM.read(p_address + 2);
	byte		byte4 = EEPROM.read(p_address + 3);

	unsigned long	firstTwoBytes =
		((byte1 << 0) & 0xFF) + ((byte2 << 8) & 0xFF00);
	unsigned long	secondTwoBytes =
		(((byte3 << 0) & 0xFF) + ((byte4 << 8) & 0xFF00));

	// multiply by 2 to power 16 - bit shift 24 to the left
	secondTwoBytes *= 65536;

	return (firstTwoBytes + secondTwoBytes);
}


/*
 * clock and time related
 */

#ifdef USE_DS1302_RTC
// extract realtime clock data from its 'funny bcd format'
// into normal integer format that we can work with
void 
unpack_rtc_bcd_data(void)
{
	my_hrs  = bcd2bin(rtc.Hrs);
	my_mins = bcd2bin(rtc.Mins);
	my_secs = bcd2bin(rtc.Secs);
}
#endif


#ifdef USE_DS1302_RTC
void
redraw_clock(byte admin_forced, byte second_hand_shown)
{
	// detect if the time had changed since last time we were called.
	// if the secs have not changed, we can exit now and save some
	// screen flicker.

	last_secs = rtc.Secs;

	// TOYclock (real time hardware TimeOfYear clock)
	rtc.GetTime();
	unpack_rtc_bcd_data();  // copies bcd stuff into binary my_hrs (etc)

	// only re-display clock if the seconds have changed OR
	// if admin-forced was 'true'
	if (rtc.Secs != last_secs || admin_forced == 1) {
		ShowTime(second_hand_shown);
	}
}
#endif


#ifdef USE_DS1302_RTC
// curent time is already saved in rtc.Hrs (etc).
// this will unpack the bcd data and print it in human readable form.
void 
ShowTime(byte second_hand_shown)
{
	byte	ms, ls;

	bin2ascii(my_hrs, &ms, &ls);
	lcd.write(ms);

	lcd.write(ls);
	lcd.write(':');

	bcd2ascii(rtc.Mins, &ms, &ls);
	lcd.write(ms);
	lcd.write(ls);

	if (second_hand_shown == 1) {
		lcd.write(':');

		bcd2ascii(rtc.Secs, &ms, &ls);
		lcd.write(ms);
		lcd.write(ls);
	}
}   
#endif	// USE_DS1302_RTC


/*
 * memory free (checkers)
 */

#ifdef USE_MEM_CHECKER
#if 0

extern unsigned int	__bss_end;
extern unsigned int	__heap_start;
extern void		*__brkval;

uint8_t			*heapptr, *stackptr;


unsigned int 
freeMemory(void) 
{
	unsigned int	free_memory;

	if ((unsigned int)__brkval == 0) {
		free_memory = ((unsigned int) &free_memory) -
			      ((unsigned int) &__bss_end);
	} 
	else {
		free_memory = ((unsigned int) &free_memory) -
			      ((unsigned int) __brkval);
	}

	return free_memory;
}


int 
availableMemory(void)
{
	int	size = 1; // = 2048; // Use 2048 with ATmega328
	char	*buf;
  
	while ((buf = (char *) malloc(size)) != NULL) {
		free(buf);	// now that we know we can get it,
				// we don't want it anymore ;)
		if (++size >= 2048)
			break;	// upper limit, even though it's absurd
	}

	return size;
}


int
availableMemory(void)
{
	stackptr = (uint8_t *) malloc(4);	// use stackptr temporarily
	heapptr = stackptr;			// save value of heap pointer
	free(stackptr);				// free up the memory again
						// (sets stackptr to 0)
	stackptr = (uint8_t *)(SP);		// save value of stack pointer

	return 1;
}

#endif	// 0
#endif	// USE_MEM_CHECKER


/*
 *  IRremote.cpp: part of the "VoluMaster(tm)" system
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
 *
 *
 * IRremote (original version)
 * Version 0.1 July, 2009
 * Copyright 2009 Ken Shirriff
 * http://arcfn.com
 *
 * Interrupt code based on NECIRrcv by Joe Knapp
 * http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?num=1210243556
 * Also influenced by:
 * http://zovirl.com/2008/11/12/building-a-universal-remote-with-an-arduino/
 */

volatile irparams_t	irparams;

// These versions of MATCH, MATCH_MARK, and MATCH_SPACE are only for debugging.
// To use them, set DEBUG in IRremoteInt.h
// Normally macros are used for efficiency
#ifdef TESTING_IR1
int 
MATCH(int measured, int desired) 
{
	Serial.print("Testing: ");
	Serial.print(TICKS_LOW(desired), DEC);
	Serial.print(" <= ");
	Serial.print(measured, DEC);
	Serial.print(" <= ");
	Serial.println(TICKS_HIGH(desired), DEC);

	return (measured >= TICKS_LOW(desired) &&
		measured <= TICKS_HIGH(desired));
}


int 
MATCH_MARK(int measured_ticks, int desired_us) 
{
	Serial.print("Testing mark ");
	Serial.print(measured_ticks * USECPERTICK, DEC);
	Serial.print(" vs ");
	Serial.print(desired_us, DEC);
	Serial.print(": ");
	Serial.print(TICKS_LOW(desired_us + MARK_EXCESS), DEC);
	Serial.print(" <= ");
	Serial.print(measured_ticks, DEC);
	Serial.print(" <= ");
	Serial.println(TICKS_HIGH(desired_us + MARK_EXCESS), DEC);

	return (measured_ticks >= TICKS_LOW(desired_us + MARK_EXCESS) &&
		measured_ticks <= TICKS_HIGH(desired_us + MARK_EXCESS));
}


int 
MATCH_SPACE(int measured_ticks, int desired_us) 
{
	Serial.print("Testing space ");
	Serial.print(measured_ticks * USECPERTICK, DEC);
	Serial.print(" vs ");
	Serial.print(desired_us, DEC);
	Serial.print(": ");
	Serial.print(TICKS_LOW(desired_us - MARK_EXCESS), DEC);
	Serial.print(" <= ");
	Serial.print(measured_ticks, DEC);
	Serial.print(" <= ");
	Serial.println(TICKS_HIGH(desired_us - MARK_EXCESS), DEC);

	return (measured_ticks >= TICKS_LOW(desired_us - MARK_EXCESS) &&
		measured_ticks <= TICKS_HIGH(desired_us - MARK_EXCESS));
}
#endif	// TESTING_IR1


/*************************
 * section for IR SEND
 *************************/

#ifdef SUPPORT_IRSEND
void 
IRsend::sendNEC(unsigned long data, int nbits)
{
	enableIROut(38);
	mark(NEC_HDR_MARK);
	space(NEC_HDR_SPACE);
	for (int i = 0; i < nbits; i++) {
		if (data & TOPBIT) {
			mark(NEC_BIT_MARK);
			space(NEC_ONE_SPACE);
		} 
		else {
			mark(NEC_BIT_MARK);
			space(NEC_ZERO_SPACE);
		}
		data <<= 1;
	}
	mark(NEC_BIT_MARK);
	space(0);
}


void 
IRsend::sendSony(unsigned long data, int nbits) 
{
	enableIROut(40);
	mark(SONY_HDR_MARK);
	space(SONY_HDR_SPACE);
	data = data << (32 - nbits);
	for (int i = 0; i < nbits; i++) {
		if (data & TOPBIT) {
			mark(SONY_ONE_MARK);
			space(SONY_HDR_SPACE);
		} 
		else {
			mark(SONY_ZERO_MARK);
			space(SONY_HDR_SPACE);
		}
		data <<= 1;
	}
}


void 
IRsend::sendRaw(unsigned int buf[], int len, int hz)
{
	enableIROut(hz);
	for (int i = 0; i < len; i++) {
		if (i & 1) {
			space(buf[i]);
		} 
		else {
			mark(buf[i]);
		}
	}
	space(0); // Just to be sure
}


// Note: first bit must be a one (start bit)
void 
IRsend::sendRC5(unsigned long data, int nbits)
{
	enableIROut(36);
	data = data << (32 - nbits);
	mark(RC5_T1); // First start bit
	space(RC5_T1); // Second start bit
	mark(RC5_T1); // Second start bit
	for (int i = 0; i < nbits; i++) {
		if (data & TOPBIT) {
			space(RC5_T1); // 1 is space, then mark
			mark(RC5_T1);
		} 
		else {
			mark(RC5_T1);
			space(RC5_T1);
		}
		data <<= 1;
	}
	space(0); // Turn off at end
}


// Caller needs to take care of flipping the toggle bit
void 
IRsend::sendRC6(unsigned long data, int nbits)
{
	int	t;

	enableIROut(36);
	data = data << (32 - nbits);
	mark(RC6_HDR_MARK);
	space(RC6_HDR_SPACE);
	mark(RC6_T1); // start bit
	space(RC6_T1);

	for (int i = 0; i < nbits; i++) {
		if (i == 3) {
			// double-wide trailer bit
			t = 2 * RC6_T1;
		} 
		else {
			t = RC6_T1;
		}

		if (data & TOPBIT) {
			mark(t);
			space(t);
		} 
		else {
			space(t);
			mark(t);
		}

		data <<= 1;
	}

	space(0); // Turn off at end
}


void 
IRsend::mark(int time) 
{
	// Sends an IR mark for the specified number of microseconds.
	// The mark output is modulated at the PWM frequency.
	TCCR2A |= _BV(COM2B1); // Enable pin 3 PWM output
	delayMicroseconds(time);
}


/* Leave pin off for time (given in microseconds) */
void 
IRsend::space(int time) 
{
	// Sends an IR space for the specified number of microseconds.
	// A space is no output, so the PWM output is disabled.
	TCCR2A &= ~(_BV(COM2B1)); // Disable pin 3 PWM output
	delayMicroseconds(time);
}


void 
IRsend::enableIROut(int khz) 
{
	// Enables IR output.  The khz value controls the modulation
	// frequency in kHz.  The IR output will be on pin 3 (OC2B).
	// This routine is designed for 36-40KHz; if you use it for
	// other values, it's up to you to make sure it gives reasonable
	// results.  (Watch out for overflow, underflow, rounding).
	// TIMER2 is used in phase-correct PWM mode, with OCR2A controlling
	// the frequency and OCR2B controlling the duty cycle.
	// There is no prescaling, so the output frequency is
	// 16MHz / (2 * OCR2A)
	// To turn the output on and off, we leave the PWM running,
	// but connect and disconnect the output pin.
	// A few hours staring at the ATmega documentation and this will
	// all make sense.  See my Secrets of Arduino PWM at
	// http://arcfn.com/2009/07/secrets-of-arduino-pwm.html for details.

	// Disable the Timer2 Interrupt (which is used for receiving IR)
	TIMSK2 &= ~_BV(TOIE2); //Timer2 Overflow Interrupt

	pinMode(3, OUTPUT);
	digitalWrite(3, LOW); // When not sending PWM, we want it low

	// COM2A = 00: disconnect OC2A
	// COM2B = 00: disconnect OC2B; to send signal set to 10: OC2B non-inverted
	// WGM2 = 101: phase-correct PWM with OCRA as top
	// CS2 = 000: no prescaling
	TCCR2A = _BV(WGM20);
	TCCR2B = _BV(WGM22) | _BV(CS20);

	// The top value for the timer.  The modulation frequency will be
	// SYSCLOCK / 2 / OCR2A.
	OCR2A = SYSCLOCK / 2 / khz / 1000;
	OCR2B = OCR2A / 3; // 33% duty cycle
}
#endif	// SUPPORT_IRSEND


/***************************
 * section for IR RECEIVE
 ***************************/

IRrecv::IRrecv(int recvpin)
{
	irparams.recvpin = recvpin;
	irparams.blinkflag = 0;  // turn it off by default
}


// initialization
void 
IRrecv::enableIRIn(void) 
{
	if (lcd_in_use_flag)
		return;	// respect the lcd mutex

	// set up pulse clock timer interrupt
	TCCR2A = 0;  // normal mode

	// Prescale /8 (16M/8 = 0.5 microseconds per tick)
	// Therefore, the timer interval can range from 0.5 to 128 microseconds
	// depending on the reset value (255 to 0)
	cbi(TCCR2B,CS22);
	sbi(TCCR2B,CS21);
	cbi(TCCR2B,CS20);

	// Timer2 Overflow Interrupt Enable
	sbi(TIMSK2,TOIE2);

	RESET_TIMER2;

	sei();  // enable interrupts

	// initialize state machine variables
	irparams.rcvstate = STATE_IDLE;
	irparams.rawlen = 0;

	// set pin modes
	pinMode(irparams.recvpin, INPUT);
}


// TIMER2 interrupt code to collect raw data.
// Widths of alternating SPACE, MARK are recorded in rawbuf.
// Recorded in ticks of 50 microseconds.
// rawlen counts the number of entries recorded so far.
// First entry is the SPACE between transmissions.
// As soon as a SPACE gets long, ready is set, state switches to IDLE, timing
// of SPACE continues.
// As soon as first MARK arrives, gap width is recorded, ready is cleared,
// and new logging starts

ISR(TIMER2_OVF_vect)
{
	if (lcd_in_use_flag)
		return;	// respect the lcd mutex

	RESET_TIMER2;

	uint8_t irdata = (uint8_t)digitalRead(irparams.recvpin);

	irparams.timer++; // One more 50us tick
	if (irparams.rawlen >= RAWBUF) {
		// Buffer overflow
		irparams.rcvstate = STATE_STOP;
	}

	switch (irparams.rcvstate) {
	case STATE_IDLE: // In the middle of a gap
		if (irdata == MARK) {
			if (irparams.timer < GAP_TICKS) {
				// Not big enough to be a gap.
				irparams.timer = 0;
			} 
			else {
				// gap just ended, record duration and
				// start recording transmission
				irparams.rawlen = 0;
				irparams.rawbuf[irparams.rawlen++] = irparams.timer;
				irparams.timer = 0;
				irparams.rcvstate = STATE_MARK;
			}
		}
		break;

	case STATE_MARK: // timing MARK
		if (irdata == SPACE) {   // MARK ended, record time
			irparams.rawbuf[irparams.rawlen++] = irparams.timer;
			irparams.timer = 0;
			irparams.rcvstate = STATE_SPACE;
		}
		break;

	case STATE_SPACE: // timing SPACE
		if (irdata == MARK) { // SPACE just ended, record it
			irparams.rawbuf[irparams.rawlen++] = irparams.timer;
			irparams.timer = 0;
			irparams.rcvstate = STATE_MARK;
		} 
		else { // SPACE
			if (irparams.timer > GAP_TICKS) {
				// big SPACE, indicates gap between codes
				// Mark current code as ready for processing
				// Switch to STOP
				// Don't reset timer; keep counting space width
				irparams.rcvstate = STATE_STOP;
			} 
		}
		break;

	case STATE_STOP: // waiting, measuring gap
		if (irdata == MARK) { // reset gap timer
			irparams.timer = 0;
		}
		break;
	}
}


void 
IRrecv::resume(void) 
{
	if (lcd_in_use_flag)
		return;	// respect the lcd mutex

	RESET_TIMER2;

	// Disable the Timer2 Interrupt (which is used for receiving IR)
	//TIMSK2 &= ~_BV(TOIE2); //Timer2 Overflow Interrupt

	irparams.rcvstate = STATE_IDLE;
	irparams.rawlen = 0;
	irparams.timer = 0;

	//results.value = 0;
}


// Decodes the received IR message
// Returns 0 if no data ready, 1 if data ready.
// Results of decoding are stored in results
int 
IRrecv::decode(decode_results *results) 
{
	results->rawbuf = irparams.rawbuf;
	results->rawlen = irparams.rawlen;

	if (irparams.rcvstate != STATE_STOP) {
		return ERR;
	}

	if (decodeSony(results)) {
		return DECODED;
	}

	if (decodeNEC(results)) {
		return DECODED;
	}

#ifdef NON_SONY
	if (decodeRC5(results)) {
		return DECODED;
	}

	if (decodeRC6(results)) {
		return DECODED;
	}
#endif // NON_SONY_IR

	results->decode_type = UNKNOWN;
	results->bits = 0;
	results->value = 0;

	return DECODED;
}


long 
IRrecv::decodeNEC(decode_results *results) 
{
	long	data = 0;
	int	offset = 1;	// Skip first space

	// Initial mark
	if (!MATCH_MARK(results->rawbuf[offset],
	   		(unsigned int) NEC_HDR_MARK)) {
		return ERR;
	}

	offset++;

	// Check for repeat
	if (irparams.rawlen == 4 &&
	    MATCH_SPACE(results->rawbuf[offset], NEC_RPT_SPACE) &&
	    MATCH_MARK(results->rawbuf[offset+1], NEC_BIT_MARK)) {
		results->bits = 0;
		results->value = REPEAT;
		results->decode_type = NEC;
		return DECODED;
	}

	if (irparams.rawlen < 2 * NEC_BITS + 4) {
		return ERR;
	}

	// Initial space  
	if (!MATCH_SPACE(results->rawbuf[offset], NEC_HDR_SPACE)) {
		return ERR;
	}

	offset++;

	for (int i = 0; i < NEC_BITS; i++) {
		if (!MATCH_MARK(results->rawbuf[offset], NEC_BIT_MARK)) {
			return ERR;
		}

		offset++;

		if (MATCH_SPACE(results->rawbuf[offset], NEC_ONE_SPACE)) {
			data = (data << 1) | 1;
		} 
		else if (MATCH_SPACE(results->rawbuf[offset],
				     NEC_ZERO_SPACE)) {
			data <<= 1;
		} 
		else {
			return ERR;
		}
		offset++;
	}

	// Success
	results->bits = NEC_BITS;
	results->value = data;
	results->decode_type = NEC;

	return DECODED;
}


long 
IRrecv::decodeSony(decode_results *results) 
{
	long	data = 0;
	if (irparams.rawlen < 2 * SONY_BITS + 2) {
		return ERR;
	}

	int offset = 1; // Skip first space
	// Initial mark
	if (!MATCH_MARK(results->rawbuf[offset], SONY_HDR_MARK)) {
		return ERR;
	}
	offset++;

	while (offset + 1 < irparams.rawlen) {
		if (!MATCH_SPACE(results->rawbuf[offset], SONY_HDR_SPACE)) {
			break;
		}
		offset++;
		if (MATCH_MARK(results->rawbuf[offset], SONY_ONE_MARK)) {
			data = (data << 1) | 1;
		} 
		else if (MATCH_MARK(results->rawbuf[offset], SONY_ZERO_MARK)) {
			data <<= 1;
		} 
		else {
			return ERR;
		}
		offset++;
	}

	// Success
	results->bits = (offset - 1) >> 1;
	if (results->bits < 12) {
		results->bits = 0;
		return ERR;
	}
	results->value = data;
	results->decode_type = SONY;

	return DECODED;
}


#ifdef NON_SONY
// Gets one undecoded level at a time from the raw buffer.
// The RC5/6 decoding is easier if the data is broken into time intervals.
// E.g. if the buffer has MARK for 2 time intervals and SPACE for 1,
// successive calls to getRClevel will return MARK, MARK, SPACE.
// offset and used are updated to keep track of the current position.
// t1 is the time interval for a single bit in microseconds.
// Returns -1 for error (measured time interval is not a multiple of t1).
uint8_t 
IRrecv::getRClevel(decode_results *results, int *offset, int *used, int t1) 
{
	if (*offset >= results->rawlen) {
		// After end of recorded buffer, assume SPACE.
		return SPACE;
	}

	int	width = results->rawbuf[*offset];
	int	val = ((*offset) % 2) ? MARK : SPACE;
	int	correction = (val == MARK) ? MARK_EXCESS : - MARK_EXCESS;
	int	avail;

	if (MATCH(width, t1 + correction)) {
		avail = 1;
	} 
	else if (MATCH(width, 2*t1 + correction)) {
		avail = 2;
	} 
	else if (MATCH(width, 3*t1 + correction)) {
		avail = 3;
	} 
	else {
		return -1;
	}

	(*used)++;

	if (*used >= avail) {
		*used = 0;
		(*offset)++;
	}

	return val;   
}


long 
IRrecv::decodeRC5(decode_results *results) 
{
	if (irparams.rawlen < MIN_RC5_SAMPLES + 2) {
		return ERR;
	}

	int	offset = 1; // Skip gap space
	long	data = 0;
	int	used = 0;

	// Get start bits
	if (getRClevel(results, &offset, &used, RC5_T1) != MARK)
		return ERR;
	if (getRClevel(results, &offset, &used, RC5_T1) != SPACE)
		return ERR;
	if (getRClevel(results, &offset, &used, RC5_T1) != MARK)
		return ERR;

	int	nbits;

	for (nbits = 0; offset < irparams.rawlen; nbits++) {
		int levelA = getRClevel(results, &offset, &used, RC5_T1); 
		int levelB = getRClevel(results, &offset, &used, RC5_T1);

		if (levelA == SPACE && levelB == MARK) {
			// 1 bit
			data = (data << 1) | 1;
		} 
		else if (levelA == MARK && levelB == SPACE) {
			// zero bit
			data <<= 1;
		} 
		else {
			return ERR;
		} 
	}

	// Success
	results->bits = nbits;
	results->value = data;
	results->decode_type = RC5;

	return DECODED;
}


long 
IRrecv::decodeRC6(decode_results *results) 
{
	if (results->rawlen < MIN_RC6_SAMPLES) {
		return ERR;
	}

	int	offset = 1; // Skip first space

	// Initial mark
	if (!MATCH_MARK(results->rawbuf[offset], RC6_HDR_MARK)) {
		return ERR;
	}

	offset++;

	if (!MATCH_SPACE(results->rawbuf[offset], RC6_HDR_SPACE)) {
		return ERR;
	}

	offset++;

	long	data = 0;
	int	used = 0;

	// Get start bit (1)
	if (getRClevel(results, &offset, &used, RC6_T1) != MARK)
		return ERR;
	if (getRClevel(results, &offset, &used, RC6_T1) != SPACE)
		return ERR;

	int	nbits;

	for (nbits = 0; offset < results->rawlen; nbits++) {
		int levelA, levelB; // Next two levels

		levelA = getRClevel(results, &offset, &used, RC6_T1); 

		if (nbits == 3) {
			// T bit is double wide; make sure second half matches
			if (levelA != getRClevel(results, &offset,
						 &used, RC6_T1))
				return ERR;
		} 

		levelB = getRClevel(results, &offset, &used, RC6_T1);

		if (nbits == 3) {
			// T bit is double wide; make sure second half matches
			if (levelB != getRClevel(results, &offset,
						 &used, RC6_T1))
				return ERR;
		} 

		if (levelA == MARK && levelB == SPACE) {
			// reversed compared to RC5
			// 1 bit
			data = (data << 1) | 1;
		} 
		else if (levelA == SPACE && levelB == MARK) {
			// zero bit
			data <<= 1;
		} 
		else {
			return ERR; // Error
		} 
	}

	// Success
	results->bits = nbits;
	results->value = data;
	results->decode_type = RC6;

	return DECODED;
}
#endif // NON_SONY


/************************************
 * IR support routines (app level)
 ************************************/

extern IRrecv	irrecv;	//(IR_PIN);
decode_results	results;
unsigned long	key;	// IR key received


#ifdef DEBUG_IR1
void
hex2ascii(const byte val, byte *ms, byte *ls)
{
	static char	hex_buf[8];

	sprintf(hex_buf, "%02x ", val);
	*ms = hex_buf[0];
	*ls = hex_buf[1];
}


void
lcd_print_long_hex(long p_value)
{
	byte	byte1 = ((p_value >> 0) & 0xFF);
	byte	byte2 = ((p_value >> 8) & 0xFF);
	byte	byte3 = ((p_value >> 16) & 0xFF);
	byte	byte4 = ((p_value >> 24) & 0xFF);
	byte	ls,ms;

	lcd.write('(');

	hex2ascii(byte4, &ms, &ls);
	lcd.write(ms);
	lcd.write(ls);

	hex2ascii(byte3, &ms, &ls);
	lcd.write(ms);
	lcd.write(ls);

	hex2ascii(byte2, &ms, &ls);
	lcd.write(ms);
	lcd.write(ls);

	hex2ascii(byte1, &ms, &ls);
	lcd.write(ms);
	lcd.write(ls);

	lcd.write(')');
}


// Dumps out the decode_results structure.
// Call this after IRrecv::decode()
// void * to work around compiler issue
//void dump(void *v) {
//  decode_results *results = (decode_results *)v
void
ir_key_dump(byte line_num)
{
	if (results.decode_type == UNKNOWN) {
		lcd.send_string("UNK: ", line_num);
	}
	else if (results.decode_type == SONY) {
		lcd.send_string("SONY: ", line_num);
	}
	else if (results.decode_type == NEC) {
		lcd.send_string("NEC: ", line_num);
	}
#ifdef NON_SONY
	else if (results.decode_type == RC5) {
		lcd.send_string("RC5: ", line_num);
	}  
	else if (results.decode_type == RC6) {
		lcd.send_string("RC6: ", line_num);
	}
#else
	else {
		lcd.send_string("UNK: ", line_num);
	}
#endif

	// print the value!
	lcd_print_long_hex(results.value);
}
#endif // DEBUG_IR1


unsigned long	last_key_value = 0;

unsigned long 
get_IR_key(void) 
{
	if (irrecv.decode(&results)) {

#ifdef DEBUG_IR
		if (results.value != 0) {
			ir_key_dump(LCD_CURS_POS_L1_HOME);
			//Serial.println(results.value, HEX);
		}
#endif

		// fix repeat codes (make them look like truly repeated keys)
		if (results.decode_type == NEC) {
			// key auto-repeat sequence
			if (results.value == 0xffffffff) {
				if (last_key_value == 0xffffffff) {
					last_key_value = 0;
				}
				results.value = last_key_value;
      			}
			else {  // was not a repeat code
				// save the first non-repeat char
				// todo: add a timestamp to this, too
				last_key_value = results.value;
			}
		}

		// fix rc5 'weird alternate same-keys logic'
		// codes with xx08xxxx are the same with the 08
		//  or a 00 in that byte location.  mask these off
		//  to 00 to create 1 unique key code for that key.
		if (results.value != 0) {
			if (results.decode_type == RC5) {
				results.value &= (unsigned long)0xffff07ff;
			}
			else if (results.decode_type == RC6) {
				results.value |= (unsigned long)0x00010000;
			}
		}

#ifdef DEBUG_IR
		if (results.value != 0) {
			ir_key_dump(LCD_CURS_POS_L2_HOME);
		}
#endif

		delay(20);
		// we just consumed one key; 'start' to receive the next value
		irrecv.resume();

		return results.value; //my_result;
	}
	else {
		return 0;   // no key pressed
	}
}


