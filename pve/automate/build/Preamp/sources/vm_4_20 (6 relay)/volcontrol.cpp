/*
 *  @(#)volcontrol.cpp	1.10 16/12/24
 *
 *  volcontrol.cpp: volume control functions
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

#ifdef USE_ANALOG_POT
// smooth the reading
int
read_analog_pot_with_smoothing(byte analog_port_num, byte reread_count)
{
	int	sensed_port_value = 0;

	for (byte i = 0; i < reread_count; i++) {
		sensed_port_value += analogRead(analog_port_num);
		// delayMicroseconds(200);
	}

	if (reread_count > 1) {
		sensed_port_value /= reread_count;
	}

	return sensed_port_value;
}


// read the pot, translate its native range to our (min..max) range
// and clip to keep any stray values in that range.
int
read_pot_volume_value_with_clipping(int sensed_pot_value)
{
	int	temp_volume;

	temp_volume = l_map(sensed_pot_value,
			0, // ANALOG_POT_MIN_RANGE,
			ANALOG_POT_MAX_RANGE,
			min_vol, max_vol);
    
	return temp_volume;
}


void
handle_analog_pot_value_changes(void)
{
	byte	old_vol;
	byte	temp_volume;
	int	sensed_pot_value;

	sensed_pot_value = read_analog_pot_with_smoothing(
		SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
	);	// to smooth it out

	if (abs(sensed_pot_value - last_seen_pot_value) > POT_CHANGE_THRESH) {
		// 1-5 is a good value to ignore noise

#ifdef DEBUG_SENSED_POT
		/*
		sprintf(buf, "CHANGE! old=[%d] new=[%d]\n",
			last_seen_pot_value, sensed_pot_value);
		Serial.print(buf);
		*/
#endif

		/*
		 * get the pot raw value into our correct volume min..max range
		 */
		old_vol = volume;	// the setting *just* before the
					// user touched the pot
		temp_volume = read_pot_volume_value_with_clipping(
			sensed_pot_value
		);
		if (temp_volume == old_vol) {
			// don't update the display (or anything) if
			// there was no *effective* change
			return;
		}

		/*
		 * if we are at this point, there was a real change and
		 * the vol engine needs to be triggered.  we also should
		 * restore backlight just as if the user had pressed a
		 * vol-change IR key.
		 */
		lcd.restore_backlight();

		volume = temp_volume;
		if (temp_volume > old_vol) {
			// are we in mute-mode right now?  if going from mute
			// to 'arrow-up' we should do a slow ramp-up first
			if (mute == 1) {
				// tell the system we are officially
				// out of mute mode, now
				mute = 0;
				update_volume(volume, 1);
			}
			else {
				// not in mute mode, handle the volume
				// increase normally.
				// this also sets the volume but also the
				// graph and db display
				update_volume(temp_volume, 0);
			}
		}
		else {
			// not a volume increase but a decrease
			// this also sets the volume but also the graph
			// and db display
			update_volume(temp_volume, 0);
		}

		/*
		 * since this registered a real change, we save the
		 * timestamp and value in our state variables
		 */
		last_seen_IR_vol_value = volume;
		last_seen_pot_value = sensed_pot_value;
	}
}


// logic on this routine is simple: the only time the pot is allowed
// to be read is when we consider the motor to be stopped (or 'settled').
void
analog_sensed_pot_logic(void)
{
	if (power == POWER_ON) {
		// does this system HAVE an analog motorized pot installed?
		if (option_pot_installed == 1) {
			// admin status is 0 for 'no motor in action, now'.
			// only read the pot IF it's not in motion 'by us'
			if (pot_state == MOTOR_SETTLED ||
			    pot_state == MOTOR_INIT) {
				handle_analog_pot_value_changes();
			}
		} // motor option was installed
	} // power was not off
}
#endif // USE_ANALOG_POT


// port_num ranges from 0 .. 7
byte
get_port_state(byte port_num)
{
	if (port_num < MAX_IOPORTS) {
		return EEPROM.read(EEPROM_PORT_STATE_BASE+port_num);
	}
	return PORT_AS_DISABLED;	// 'n/a'
}


// port_num ranges from 0 .. 7
void
set_port_state(byte port_num, byte state)
{
	if (port_num < MAX_IOPORTS) {
		//EEPROM.write(EEPROM_PORT_STATE_BASE + port_num, state);
	}
}


#if defined(USE_D1_RELAYS) || defined(USE_D2_RELAYS)
void
relay_common_delay_then_release(byte pcf_a, byte pcf_b, byte pcf_c, byte pcf_d)
{
	// relays were just clicked.  we have a common delay to
	// let them settle before we unlatch them
	delayMicroseconds(CLICK_DOWN_DELAY);

	// do the unlatch (relax) stuff
	// left side of relay coil
	pcf.write(delta_i2c_addr[pcf_a], 0);
	// right side of relay coil
	pcf.write(delta_i2c_addr[pcf_b], 0);

	// the secondary controller and its relays ('balanced' configs)
	if ( (pcf_c != 255) && (pcf_d != 255) ) {
		// left side of relay coil
		pcf.write(delta_i2c_addr[pcf_c], 0);
		// right side of relay coil
		pcf.write(delta_i2c_addr[pcf_d], 0);
	}

	// let the relay 'hold' for a while
	delayMicroseconds(CLICK_UP_DELAY);
}
#endif // USE_D1_RELAYS USE_D2_RELAYS


// pcf_a and pcf_b are integer index values in the I2C array.
// vol_byte is the value we want to write to the relay board
// forced_update_flag==1 means we ignore any last_relay_state and
// force-set all bits
// note: value of '255' is a sentinel/flag value.  legal values are 0..7.

void
do_relay_latching(byte pcf_a, byte pcf_b,	// first pair of i2c addr's
		  byte pcf_c, byte pcf_d,	// optional 2nd pair
						// (balanced config)
		  byte vol_byte,		// the 0..255 value to write
		  byte my_installed_relay_count, // how many bits are installed
		  byte forced_update_flag)	// abs or relative mode (1=abs)
{
#if defined(USE_D1_RELAYS) || defined(USE_D2_RELAYS)
	// we need this to be able to underflow to *negative* numbers
	// so our loop will exit properly
	int	bitnum;

	byte	mask_left;
	byte	mask_right;
	byte	just_the_current_bit;
	byte	just_the_previous_bit;
	byte	shifted_one_bit;

	/*
	 * walk ALL the bits and just count the bit-changes and save
	 * into left and right masks, for this pass
	 */
	// bit_changes = 0;
	mask_left = mask_right = 0;

	// this loop walks ALL bits, even the 'mute bit'
	for (bitnum = (my_installed_relay_count-1); bitnum >= 0 ; bitnum--) {
		// optimize: calc this ONLY once per loop
		shifted_one_bit = (1 << bitnum);

		// this is the new volume value; and just the bit
		// we are walking, right now
		just_the_current_bit = (vol_byte & shifted_one_bit);

		// logical AND to extra just the bit we are interested in
		just_the_previous_bit = (last_volume & shifted_one_bit);

		// examine our current bit and see if it changed from
		// the last run
		if (just_the_previous_bit != just_the_current_bit ||
		    forced_update_flag == 1) {
			// we did find a bit that changed, so bump
			// our change-counter var
			//bit_changes++;

			// latch the '1' on the left or right side of
			// the relay?
			if (just_the_current_bit != 0) {
				// a '1' in this bit pos
				// (1 << bitnum);
				mask_left |= ((byte)shifted_one_bit);
			} 
			else {
				// (1 << bitnum);
				mask_right |= ((byte)shifted_one_bit);
			}
		} // the 2 bits were different
	} // for each of the 8 bits

	/*
	 * slam down all 8 bits; first one side, then wait, then release,
	 * then do the same for the other side
	 */
	// mask right
	pcf.write(delta_i2c_addr[pcf_b], mask_right);
	pcf.write(delta_i2c_addr[pcf_a], 0x00);

	if (pcf_c != 255 && pcf_d != 255) {
		pcf.write(delta_i2c_addr[pcf_d], mask_right);
		pcf.write(delta_i2c_addr[pcf_c], 0x00);
	}
	relay_common_delay_then_release(pcf_a, pcf_b, pcf_c, pcf_d);

	// mask left
	pcf.write(delta_i2c_addr[pcf_a], mask_left);
	pcf.write(delta_i2c_addr[pcf_b], 0x00);

	if (pcf_c != 255 && pcf_d != 255) {
		pcf.write(delta_i2c_addr[pcf_c], mask_left);
		pcf.write(delta_i2c_addr[pcf_d], 0x00);
	}
	relay_common_delay_then_release(pcf_a, pcf_b, pcf_c, pcf_d);
#endif // USE_D1_RELAYS USE_D2_RELAYS
}


// sample call: vol_change(VC_UP, VC_FAST);
void
vol_change_relative(byte dir_flag, byte speed_flag)
{
	if (option_delta1_board_count == 0)
		return;	// no vol engines!

	/*
	 * some quick exit tests
	 */

	if (power == POWER_OFF)
		return;	// power was in the 'off' or 'standby' state

	if (dir_flag == VC_UP) {
		if (volume >= max_vol)
			// user asked us to raise volume beyond our max.
			return;
	} 
	else if (dir_flag == VC_DOWN) {
		if (volume <= min_vol)
			// user asked us to lower volume beyond our min.
			return;
	}

	// ok, we have to actually do something.
	lcd.restore_backlight();

	// are we in mute-mode right now?  if going from mute to 'arrow-up'
	// (or 'arrow-right'),
	// we should auto-exit from mute and also let the volume
	// increment take affect.
	if (mute == 1 && dir_flag == VC_UP) {
		mute = 0;
		redraw_volume_display(volume, 1);
	}

	/*
	 * call the vol-control engine
	 */
	if (dir_flag == VC_UP) {
		if (speed_flag == VC_SLOW) {    
			// up-slow
			if (volume < max_vol &&
			   (volume + NATIVE_VOL_RATE) < max_vol) {
				volume += NATIVE_VOL_RATE;
			} 
			else {
				volume = max_vol;
			}

			update_volume(volume, 0);  // 0='relative mode'
		} 
		else if (speed_flag == VC_FAST) {
			// up-fast
			if (volume < (max_vol - vol_coarse_incr)) {
				volume += vol_coarse_incr;
			} 
			else {
				volume = max_vol;
			}

			update_volume(volume, 0);  // 0='relative mode'
		}
	}
	else if (dir_flag == VC_DOWN) {
		if (speed_flag == VC_SLOW) {
			// down-slow
			if (volume > min_vol &&
			   (volume - NATIVE_VOL_RATE) > min_vol) {
				volume -= NATIVE_VOL_RATE;
			} 
			else {
				volume = min_vol;
			}

			update_volume(volume, 0);  // 0='relative mode'
		} 
		else if (speed_flag == VC_FAST) {
			// down-fast
			if (volume > (min_vol + vol_coarse_incr)) {
				volume -= vol_coarse_incr;
			} 
			else {
				volume = min_vol;
			}

			update_volume(volume, 0);  // 0='relative mode'
		}
	}
}


void
format_volume_to_string_buf(byte volume, char *ascii_vol_buf)
{
	int	display_val;
	byte	half_db_flag;
	byte	sign_flag;	// '+' or '-' or ' '
#ifdef USE_PGA_I2C
	int	f;
	char	pga_db_buf[8];
#endif

	sign_flag = '-';	// assume it's 'minus', by default

	// this gives us a true negative number for atten's
	display_val = ((int) volume - (int) max_byte_size);

#ifdef USE_PGA_I2C
	// if this is a PGA engine, simply add +32 to the value to
	// map it to the -96..+32 range
	if (option_delta1_board_count == 3) {
		f = (5 * display_val);	// divide by 2 and scale by 10
					// to avoid a decimal point
					// (10/2=5, so we just mult by 5)

		// pga is always 31.5 shifted (to give positive gain
		// as well as attenuation)
		f += 315;		// 315 = 13.5*10, to avoid FP math

		// print the leading + or - sign
		if (f > 0)
			sign_flag = '+';
		else if (f == 0)
			sign_flag = ' ';

		// create "315" from the value 31.5
		sprintf(pga_db_buf, "%03d", abs(f));

		// create "- 31.5dB"
#ifdef USE_BIGFONTS
		if (big_mode == 1 && toplevel_mode == TOPLEVEL_MODE_NORMAL) {
			sprintf(ascii_vol_buf, "%c%c%c%cdB", 
				sign_flag, 
				pga_db_buf[0],  // tens
				pga_db_buf[1],  // units
				pga_db_buf[2]); // fraction (.0 or .5)
		}
#endif
		else {
			sprintf(ascii_vol_buf, "%c %c%c.%cdB", 
				sign_flag, 
				pga_db_buf[0],  // tens
				pga_db_buf[1],  // units
				pga_db_buf[2]); // fraction (.0 or .5)
		}
		return;
	}
#endif // USE_PGA_I2C

#ifdef USE_D1_RELAYS
	/*
	 * this is all relay-based printf code, now
	 */
	if (display_val == 0) {
		// remove any + or - signs if the vol is exactly zero
		sign_flag = ' ';
	}

	// now remove the sign from the raw number since we manually manage
	// the sign on our own
	display_val = abs(display_val); 

	// print based on our db-stepsize

	if (option_db_step_size == DB_STEPSIZE_TENTH) {
#ifdef USE_BIGFONTS
		if (big_mode == 1 && toplevel_mode == TOPLEVEL_MODE_NORMAL) {
			sprintf(ascii_vol_buf, "%c%2d%d",
				sign_flag, display_val / 10, display_val % 10);
		}
		else
#endif
		{
			sprintf(ascii_vol_buf, "%c%3d.%d",
				sign_flag, display_val / 10, display_val % 10);
		}
	} 
	else if (option_db_step_size == DB_STEPSIZE_HALF) {
		if (display_val & 0x01) {
			// on odd numbers, set the 'we need a .5dB
			// printout' flag
			half_db_flag = '5';
		}
		else {
			// even numbers, we print a .0dB instead
			half_db_flag = '0';
		}

		display_val /= 2;

#ifdef USE_BIGFONTS
		if (big_mode == 1 && toplevel_mode == TOPLEVEL_MODE_NORMAL) {
			// check to see if min_vol will be greater than -100dB
			// so we can determine whether to show the negative
			// sign.
			if (min_vol > 55) {
				sprintf(ascii_vol_buf, "%c%2d%c",
					sign_flag, display_val, half_db_flag);
			}
			else {
				sprintf(ascii_vol_buf, "%3d%c",
					display_val, half_db_flag);
			}
		}
		else
#endif
		{
			sprintf(ascii_vol_buf, "%c%3d.%c",
				sign_flag, display_val, half_db_flag);
		}
	}
	else if (option_db_step_size == DB_STEPSIZE_WHOLE) {
		const char	*pad;

		pad = (toplevel_mode == TOPLEVEL_MODE_NORMAL) ? "" : "  ";

		if (display_val == 0)
			sprintf(ascii_vol_buf, " %s%3d", pad, display_val);
		else
			sprintf(ascii_vol_buf, "%s%c%3d",
				pad, sign_flag, display_val);
	}

	strcat(ascii_vol_buf, "dB");
#endif // USE_D1_RELAYS

}


// forced_update_flag==1 means we ignore any last_relay_state and
// force-set all bits
void
send_vol_to_all_delta1_boards(byte vol_byte, byte forced_update_flag)
{
#ifdef USE_D1_RELAYS
	/*
	 * handle all the relay latching complexity
	 */
	if (option_delta1_board_count == 1) {
		do_relay_latching(0, 1,		// first d1 board (2 PEs)
				  255, 255,	// NO 2nd d1 board (0 PEs)
				  vol_byte, 
				  installed_relay_count, 
				  forced_update_flag);

	}
	else if (option_delta1_board_count == 2) {	// a 2nd delta1 board
		// add in the secondary controller and its relays
		// ('balanced' configs)
		do_relay_latching(0, 1,		// first d1 board (2 PEs)
				  2, 3,		// 2nd d1 board (2 PEs)
				  vol_byte, 
				  installed_relay_count, 
				  forced_update_flag);
	}
#endif // USE_D1_RELAYS
}


void
send_vol_byte_to_engines(byte vol_byte, byte forced_admin_flag)
{
	if (mute == 1)
		return;	// global mute disables any vol-changes

	/*
	 * if there is a PGA chip, send data to it.  the routine will
	 * test if chip exists.
	 */
	if (vol_byte != last_volume || forced_admin_flag) {
#ifdef USE_PGA_I2C
		pga2311_set_volume(vol_byte, vol_byte);
#endif

		/*
		 * if there are delta1 boards, send data to them.
		 * the routine will test if boards exist.
		 */
#ifdef USE_D1_RELAYS
		send_vol_to_all_delta1_boards(vol_byte, forced_admin_flag);
#endif

		// here is where we capture our last-used value
		last_volume = vol_byte;
	}

	/*
	 * we don't always spend cycles writing the value to EEPROM,
	 * but we save a timestamp of the last time we wrote a new value
	 * and if it's 'too old' at some point, the eeprom writer task
	 * (routine) will flush it to eeprom.
	 */
	EEwrite_cached_vol_value_write(vol_byte);
}


void
redraw_volume_display(byte vol_byte, byte forced_admin_flag)
{
#ifdef USE_BIGFONTS
	if (big_mode == 1)
		redraw_volume_display_bigfonts(vol_byte);
	else
#endif
		redraw_volume_display_smallfonts(vol_byte, forced_admin_flag);
}


void
redraw_volume_display_smallfonts(byte vol_byte, byte forced_admin_flag)
{
	int	x_val;

	if (option_delta1_board_count != 0) {
		/*
		 * if vol-control engine enabled, always display dB numbers
		 * in the right/bottom area
		 */
		format_volume_to_string_buf(vol_byte, string_buf);
		lcd.command(LCD_CURS_POS_L2_HOME + lcd_phys_rows -
			    strlen(string_buf));
		 // display formated volume string
		lcd.send_string(string_buf, 0);
	} 

	// if we have to do a redraw, always clear out the lower/left area
	if (forced_admin_flag == 1) {
		/*
		 * bottom/left: draw either:
		 *   - MUTE	(temp muting)
		 *   - (S59)	(sleep count-down mode)
		 *   - HH:MM	(clock mode)
		 *   - bargraph	(all other cases; but also the usual case)
		 */
		if (mute == 1) {
			lcd_clear_8_chars(LCD_MAIN_MUTE_LOC);
			lcd.send_string_P(fl_st_MUTE, LCD_MAIN_MUTE_LOC);
		}
#ifdef USE_DS1302_RTC
		else if (display_mode == EEPROM_DISP_MODE_CLOCK) {
			if (option_ds1302_rtc_installed == RTC_INSTALLED) {
				update_alternate_clock_display(1);
			}
		}
#endif
		else if (display_mode == EEPROM_DISP_MODE_SLEEP) {
			update_sleep_display_time(1);
		}
	}	// forced admin part

	if (display_mode == EEPROM_DISP_MODE_BARGRAPH && mute != 1) {
		if (option_delta1_board_count == 0) {
			lcd_clear_8_chars(LCD_MAIN_MUTE_LOC);
		}
		else {
			if (vol_span == 0) {
				x_val = (int) (vol_byte * 100) / (int) 0xff;
			}
			else {
				x_val = abs(vol_byte - min_vol);
				x_val = (int) (x_val * 100) / (int) vol_span;
			}
      
			lcd.draw_graphic_bar(
				string_buf, 
				x_val,
				// max size of graph, in char-cells
				char_cell_graph_size
			);
      
			// print bargraph to lcd
			lcd.send_string(string_buf, LCD_CURS_POS_L2_HOME);
		}
	}
}


#ifdef USE_BIGFONTS
void
redraw_volume_display_bigfonts(byte vol_byte)
{
	if (option_delta1_board_count == 0)
		return;	// no more to display

	format_volume_to_string_buf(vol_byte, string_buf);

	// display volume as BIG numerals
	lcd.draw_big_numeral_db_chars(string_buf);
}
#endif	// USE_BIGFONTS


/*
 * send the 'common' volume to all volume control engines.
 * also update the bottom half of the lcd display (graph, db value, etc)
 */
void 
update_volume(byte vol_byte, byte forced_admin_flag)
{
	/*
	 * this really sends a vol-change to all our engines
	 */
	send_vol_byte_to_engines(vol_byte, forced_admin_flag);

	// redraw the bottom line of the screen
	redraw_volume_display(volume, forced_admin_flag);
}


#ifdef USE_MOTOR_POT
void
motor_pid(void)
{
	int	target_pot_wiper_value;
	int	admin_sensed_pot_value;

	// given the 'IR' set volume level, find out what wiper value
	// we should be comparing with
	target_pot_wiper_value = l_map(volume, min_vol, max_vol,
					ANALOG_POT_MIN_RANGE,
					ANALOG_POT_MAX_RANGE);
  
	// this is the oper value of the pot, from the a/d converter
	admin_sensed_pot_value = read_analog_pot_with_smoothing(
		SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
	);
  
	if (abs(target_pot_wiper_value - admin_sensed_pot_value) <= 8) {
		// stop the motor!
		digitalWrite(MOTOR_POT_ROTATE_CCW, LOW);  // stop turning left
		digitalWrite(MOTOR_POT_ROTATE_CW,  LOW);  // stop turning right
		pot_state = MOTOR_COASTING;
		delay(5);  // 5ms
		return;
	}
	else {
		/*
		 * not at target volume yet
		 */

		if (admin_sensed_pot_value < target_pot_wiper_value) {
			// turn clockwise

			// stop turning left
			digitalWrite(MOTOR_POT_ROTATE_CCW, LOW);
			// start turning right
			digitalWrite(MOTOR_POT_ROTATE_CW,  HIGH);
		}
		else if (admin_sensed_pot_value > target_pot_wiper_value) {
			// turn counter-clockwise

			// stop turning right
			digitalWrite(MOTOR_POT_ROTATE_CW,  LOW);
			// start turning left
			digitalWrite(MOTOR_POT_ROTATE_CCW, HIGH);
		}
	}
} 


// a state-driven dispatcher
void
motor_pot_logic(void)
{
	int		admin_sensed_pot_value = 0;
	static int	motor_stabilized;

	/*
	 * simple PID control for motor pot
	 */

	if (power == POWER_OFF)
		return;

	// If max_vol == min_vol then don't run the motor
	if (vol_span == 0)
		return;

#if 0
	if (mute == 1)
		return;	// don't spin the motor if the user
			// just went down to MUTE
#endif

	switch (pot_state) {
	case MOTOR_INIT:
		/*
		 * initial state, just go to 'settled' from here
		 */
		pot_state = MOTOR_SETTLED;
		last_seen_IR_vol_value = volume;
		break;

	case MOTOR_SETTLED:
		/*
		 * if we are 'settled' and the pot wiper changed,
		 * it was via a human.  this doesn't affect our
		 * motor-driven logic.
		 */
		// if the volume changed via the user's IR, this should
		// trigger us to move to the next state
		if (volume != last_seen_IR_vol_value) {
			pot_state = MOTOR_IN_MOTION;
			last_seen_pot_value = read_analog_pot_with_smoothing(
				SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
			);
		}

		last_seen_IR_vol_value = volume;
		break;

	case MOTOR_IN_MOTION:
		/*
		 * if the motor is moving, we are looking for our target
		 * so we can let go of the motor and let it 'coast' to a stop
		 */
		lcd.restore_backlight();

		motor_stabilized = 0;
		motor_pid();
		break;

	case MOTOR_COASTING:
		/*
		 * we are waiting for the motor to stop
		 * (which means the last value == this value)
		 */
		lcd.restore_backlight();
		delay(20);
		admin_sensed_pot_value = read_analog_pot_with_smoothing(
			SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
		);
		if (admin_sensed_pot_value == last_seen_pot_value) {
			if (++motor_stabilized >= 5) {
				// yay! we reached our target
				pot_state = MOTOR_SETTLED;
			}
		}
		else {
			// we found a value that didn't match,
			// so reset our 'sameness' counter
			motor_stabilized = 0;
		}

		// this is the operating value of the pot,
		// from the a/d converter
		last_seen_pot_value = admin_sensed_pot_value;
		break;

	default:
		break;
	}
}
#endif // USE_MOTOR_POT


void 
change_input_selector(byte new_in_sel)
{
#ifdef USE_SPDIF
	byte	inverted_shifted_mask;
#endif

	// forced admin; write to eeprom to save current value to 'old' portnum
	//cache_flush_save_current_vol_level(1);

	// copy to RAM (globals)
	input_selector = new_in_sel;
	//EEPROM.write(EEPROM_INPUT_SEL, input_selector);

	/*
	 * restore last-used volume setting based on this input selector switch
	 * note: if in 'global mute' mode, don't touch any volume setting
	 * in the engine!
	 */
   
	//if (option_delta1_board_count != 0) {
	//	if (mute != 1) {
	//		send_vol_byte_to_engines(0, 0);	// volume mute
	//		delay(2);
	//	}

	//	volume = EEPROM.read(EEPROM_PORT_VOL_BASE + input_selector);

	//	if (volume > max_vol)
	//		volume = max_vol;
	//	if (volume < min_vol)
	//		volume = min_vol;

	//	if (mute != 1) {
	//		// volume restore (based on the new input port)
	//		send_vol_byte_to_engines(volume, 1);
	//	}

		// forced admin; write to eeprom even if the cache 'suggests'
		// it's too early
	//	cache_flush_save_current_vol_level(1);
	//}

	/*
	 * relay based i/o ?
	 */

#ifdef USE_D2_RELAYS
	if (option_delta2_board_count == 1 ||
	    option_delta2_board_count == 2) {
		// engage the right relays based on this new input-selector
		// this CLEARS all input bits!
		update_delta2_state(output_selector_mask);
		delay(2);  // break-before-make
		// mash-up both input and output masks
		update_delta2_state((1 << (7-input_selector)) |
				    output_selector_mask);
	}
#endif

	/*
	 * spdif (etc) i/o ?
	 */
#ifdef USE_SPDIF
	if (option_delta2_board_count == 3) {		// s-addr type
		// lower part of byte is the address, in binary.
		// upper part of byte is a mask used to light 'courtesy leds' ;)
		inverted_shifted_mask = ~(1 << (input_selector+4));
		inverted_shifted_mask &= B11110000; // only keep the top 4 bits
		pcf.write(delta_i2c_addr[I2C_SPDIF_ADDR_SLOT],
			inverted_shifted_mask | (input_selector+0)
		);
	}
	else if (option_delta2_board_count == 4) {	// s-mask type
		// this is a 'break before make'
		pcf.write(delta_i2c_addr[I2C_SPDIF_ADDR_SLOT], 0);
		delay(2);
		// wire YOUR hardware correctly!
		pcf.write(delta_i2c_addr[I2C_SPDIF_ADDR_SLOT],
			  (1 << (7-input_selector)));
	}
#endif
	//common_startup(1);
}


void 
change_output_selector(byte new_out_sel, byte new_out_sel_mask)
{
	// part of our job is to save these to EEPROM
	//EEPROM.write(EEPROM_OUTPUT_SEL,      new_out_sel);
	//EEPROM.write(EEPROM_OUTPUT_SEL_MASK, new_out_sel_mask);

	// copy to RAM (globals), too
	output_selector      = new_out_sel;
	output_selector_mask = new_out_sel_mask;

	/*
	 * relay based i/o ?
	 */
#ifdef USE_D2_RELAYS
	if (option_delta2_board_count == 1 ||
	    option_delta2_board_count == 2) {
		// engage the right relays based on this new input-selector
		// mash-up both input and output masks
		update_delta2_state((1 << (7-input_selector)) |
				    output_selector_mask);
	}
#endif
}


void
EEwrite_cached_vol_value_write(byte volume)
{
	// invalidate the cache since our new value is not the same
	// as the one in EEPROM, now
	eewrite_cur_vol_dirtybit = 1;
	eewrite_cur_vol_ts = millis();	// mark the time of our
					// last value_change event
	eewrite_cur_vol_value = volume;
}


void 
cache_flush_save_current_vol_level(byte admin_forced_write_flag)
{
	// if the user does NOT force a flush, follow normal checking procedure
	if (admin_forced_write_flag == 0) {
		// if our value is not in sync with what's in EEPROM
		if (eewrite_cur_vol_dirtybit != 1) {
			return;
		}

		// extra check: only save vol level if it's been longer
		// than X amount of time since last EEPROM vol level write
		if (abs(millis() - eewrite_cur_vol_ts) <=
			EEPROM_VOL_FLUSH_INTERVAL) {
			return;
		}
	}
	else {
		eewrite_cur_vol_value = volume; // capture the value, right now
	}

	//EEPROM.write(EEPROM_INPUT_SEL, input_selector);
	//EEPROM.write(EEPROM_PORT_VOL_BASE + input_selector,
  //  		     eewrite_cur_vol_value);
  	eewrite_cur_vol_dirtybit = 0;	// clear the dirtybit flag
  	eewrite_cur_vol_ts = 0;		// reset our timestamp
}


byte
reverse_bit_order(byte flag)
{
	byte	new_flag;
	byte	bitpos;

	// reverse the order of the bits
	new_flag = 0;

	for (bitpos = 0; bitpos < 8; bitpos++) {
		// if this is a 'one' bit
		if (flag & (1 << bitpos)) {
			// then set it in the target
			new_flag |= ((byte)(1 << (7-bitpos)));
		}
	}

	return new_flag;
}


#ifdef USE_D2_RELAYS
// this is the combined input and output MASKS, logically ORed
// with each other to form 1 byte
void
update_delta2_state(byte port_bits)
{
	port_bits = reverse_bit_order(port_bits);

	/*
	 * handle all the relay latching complexity
	 */
	if (option_delta2_board_count == 1) {
		do_relay_latching(4, 5,		// first d2 board (2 PEs)
				  255, 255,	// NO 2nd d2 board (0 PEs)
				  port_bits, 
				  8,		// installed_relay_count
				  1		// forced_update_flag
		);
	}
	else if (option_delta2_board_count == 2) {	// a 2nd delta2 board
		// add in the secondary controller and its relays
		// ('balanced' configs)
		do_relay_latching(4, 5,		// first d2 board (2 PEs)
				  6, 7,		// 2nd d2 board (2 PEs)
				  port_bits, 
				  8,		// installed_relay_count
				  1		// forced_update_flag
		);
	}
}
#endif // USE_D2_RELAYS


