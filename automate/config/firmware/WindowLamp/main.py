
# Import necessary modules
import network
import socket
import time
import random
from machine import Pin

# Wi-Fi credentials
from wifi_creds import ssid, password

# Create an LED object on pin 'LED'
led = Pin(21, Pin.OUT)

# Connect to WLAN
wlan = network.WLAN(network.STA_IF)
wlan.active(True)
wlan.connect(ssid, password)

# Wait for Wi-Fi connection
connection_timeout = 10
while connection_timeout > 0:
    if wlan.status() >= 3:
        break
    connection_timeout -= 1
    print('Waiting for Wi-Fi connection...')
    time.sleep(1)

# Check if connection is successful
if wlan.status() != 3:
    raise RuntimeError('Failed to establish a network connection')
else:
    print('Connection successful!')
    network_info = wlan.ifconfig()
    print('IP address:', network_info[0])

# Set up socket and start listening
addr = socket.getaddrinfo('0.0.0.0', 80)[0][-1]
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(addr)
s.listen()

print('Listening on', addr)


# Main loop to listen for connections
while True:
    try:
        response = 'X'
        conn, addr = s.accept()
        print('Got a connection from', addr)
        
        # Receive and parse the request
        request = conn.recv(1024)
        request = str(request)
        print('Request content = %s' % request)

        try:
            request = request.split()[1]
            print('Request:', request)
        except IndexError:
            pass
        
        # Process the request and update variables
        if request == '/led1on?':
            print("turning LED on")
            led.value(0)
            response = '|1|'
        elif request == '/led1off?':
            print("turning LED off")
            led.value(1)
            response = '|0|'

        # Send the HTTP response and close the connection
        conn.send('HTTP/1.0 200 OK\r\nContent-type: text/plain\r\n\r\n')
        conn.send(response + '\n')
        conn.close()

    except OSError as e:
        conn.close()
        print('Connection closed')
        
        