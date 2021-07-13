#!/usr/bin/python3
##### Light Detection Program for IR Camera #####
## by Ben Provenzano III - 07/08/2021

import RPi.GPIO as GPIO
import time
GPIO.setmode(GPIO.BCM)

delayt = 2.5
value = 0
ldr = 22
irleds = 27
ircut = 17

GPIO.setup(irleds, GPIO.OUT)
GPIO.output(irleds, False)
GPIO.setup(ircut, GPIO.OUT)
GPIO.output(ircut, True)

## Read time GPIO pin takes to go low
def rc_time (ldr):
    count = 0

    GPIO.setup(ldr, GPIO.OUT)
    GPIO.output(ldr, False)
    time.sleep(delayt)
    GPIO.setup(ldr, GPIO.IN)

    while (GPIO.input(ldr) == 0):
        count += 1
        if (count > 65000):
            break

    return count

## Main Loop
try:
    while True:
        #print("LDR Time Constant:")
        value = rc_time(ldr)
        #print(value)

        if ( value >= 60000 ):
                #print("Turning on IR LEDs & cut filter")
                GPIO.output(ircut, True)
                GPIO.output(irleds, True)  
        if ( value <= 20000 ):
                #print("Turning off IR LEDs & cut filter")
                GPIO.output(ircut, False)
                GPIO.output(irleds, False)
        #print(" ")        

except KeyboardInterrupt:
    pass
finally:
    GPIO.cleanup()
