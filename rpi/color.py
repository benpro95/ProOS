#!/opt/rpi/pythproc

# Open Pixel Control client: Parse RGB Values into Light

import time
import sys
import opc

var = sys.argv[1:]

numLEDs = 512
client = opc.Client('127.0.0.1:7890')

color = [ (var) ] * numLEDs

time.sleep(0.1)
client.put_pixels(color)
time.sleep(0.1)
client.put_pixels(color)
time.sleep(0.1)
client.put_pixels(color)
time.sleep(0.1)
client.put_pixels(color)
time.sleep(0.1)
client.put_pixels(color)

exit()
