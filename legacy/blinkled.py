#!/usr/bin/python3

import RPi.GPIO as GPIO
import time

LED = 12

GPIO.setwarnings(False) 
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED,GPIO.OUT)

GPIO.output(LED, 1)
time.sleep(0.400)
GPIO.output(LED, 0)





