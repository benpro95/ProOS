#!/usr/bin/python3
# Ben Provenzano III
# uses BCM pin numbering
# when front panel button is held down for +2 seconds lights are turned off, 
# when held +6 seconds network is toggled between wifi client and wifi access point modes.

use_button=13

from gpiozero import Button
from signal import pause
import subprocess

held_for=0.0

def rls():
        global held_for
        if (held_for > 6.0):
                subprocess.call("/bin/bash /opt/rpi/init togglenet </dev/null &>/dev/null &", shell=True)
        elif (held_for > 2.0):
                subprocess.call("/bin/bash /opt/rpi/leds stop </dev/null &>/dev/null &", shell=True)
        else:
                held_for = 0.0

def hld():
        # callback for when button is held
        #  is called every hold_time seconds
        global held_for
        # need to use max() as held_time resets to zero on last callback
        held_for = max(held_for, button.held_time + button.hold_time)

button=Button(use_button, hold_time=1.0, hold_repeat=True)
button.when_held = hld
button.when_released = rls

pause() # wait forever