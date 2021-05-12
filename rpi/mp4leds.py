#!/usr/bin/env /opt/rpi/pythproc
#
# by Ben Provenzano III - Jan 1st 2017
#

import signal
import sys
import numpy as np
import math
import cv2
import opc
import time

print "Starting VideoLEDs - press CTRL-C to exit"

cap = cv2.VideoCapture('/tmp/movie.mp4')

# Initialize the client connection to the local fcserver.
client = opc.Client('127.0.0.1:7890')

# For transforming the captured frame to a reduced resolution frame.
# TODO: get camera resolution from API
frame_counter = 0
capCols = 640
capRows = 480
MIRROR_COLS = 40
MIRROR_ROWS = 40

colStep = math.floor(float(capCols) / MIRROR_COLS)
rowStep = math.floor(float(capRows) / MIRROR_ROWS)

while(True):
    # Capture a frame
    ret, frame = cap.read()
    frame_counter += 1
    #If the last frame is reached, reset the capture and the frame_counter
    if frame_counter == cap.get(cv2.CAP_PROP_FRAME_COUNT):
        frame_counter = 0 #Or whatever as long as it is the same as next line
        cap.set(cv2.CAP_PROP_POS_FRAMES, 0)

    reducedFrame = cv2.resize(frame, (MIRROR_ROWS, MIRROR_COLS))

    # Flip y-axis to match mirror's setup
    reducedFrame = reducedFrame[:, ::-1]
                    
    # The Neopixel grid is addressed as a 2-dmensional array, so
    # reshape the data to match
    ledArray = np.reshape(reducedFrame, (reducedFrame.shape[0] *  reducedFrame.shape[1], 3), 'F')
                        
    # Send it on to the FadeCandy controller
    client.put_pixels(ledArray)
    time.sleep(0.025)

# When all is done, release the capture
cap.release()
cv2.destroyAllWindows()

exit
