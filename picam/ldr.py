import RPi.GPIO as GPIO
import time
GPIO.setmode(GPIO.BCM)

delayt = 1.5
value = 0
ldr = 22
irleds = 27
ircut = 17

GPIO.setup(irleds, GPIO.OUT)
GPIO.output(irleds, False)
GPIO.setup(ircut, GPIO.OUT)
GPIO.output(ircut, True)

def rc_time (ldr):
    count = 0

    GPIO.setup(ldr, GPIO.OUT)
    GPIO.output(ldr, False)
    time.sleep(delayt)
    GPIO.setup(ldr, GPIO.IN)

    while (GPIO.input(ldr) == 0):
        count += 1

    return count


try:
    # Main loop
    while True:
        print("Ldr Value:")
        value = rc_time(ldr)
        print(value)

        if (value > 80000):
                print("Dark out!")
                print("Turning on IR LEDs & cut filter..")
                GPIO.output(ircut, True)
                GPIO.output(irleds, True)  
        if ( value <= 40000 ):
                print("Bright out!")
                print("Turning off IR LEDs & cut filter..")
                GPIO.output(ircut, False)
                GPIO.output(irleds, False)
        print(" ")        

except KeyboardInterrupt:
    pass
finally:
    GPIO.cleanup()
