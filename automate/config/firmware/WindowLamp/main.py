
# Import necessary modules
import network
import socket
import time
import random
from machine import Pin

# Wi-Fi credentials
from wifi_creds import ssid, password

def sendResponse(data):
    return '|' + str(data) + '|'

def webServer(socket):
    try:
        response = 'X'
        conn, addr = socket.accept()
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
        
        # Process the request
        if request == '/led1on?':
            print("turning LED #1 on")
            led1.value(0) ## active-low
            response = sendResponse(1);   
            
        elif request == '/led1off?':
            print("turning LED #1 off")
            led1.value(1)
            response = sendResponse(0);   
            
        elif request == '/led1?':
            print("LED #1 status")
            if led1.value() == 0: ## active-low
              response = sendResponse(1);
            else:
              response = sendResponse(0);  

        elif request == '/led1toggle?':
            print("toggling LED #1 power")
            if led1.value() == 1:
                led1.value(0)  ## active-low
                response = sendResponse(1);
            else:
                led1.value(1)
                response = sendResponse(0);
            
        # Send the HTTP response and close the connection
        conn.send('HTTP/1.0 200 OK\r\nContent-type: text/plain\r\n\r\n')
        conn.send(response + '\n')
        conn.close()
        
    except OSError as e:
        conn.close()
        print('Connection closed')

def openSocket():
    # Set up socket and start listening
    addr = socket.getaddrinfo('0.0.0.0', 80)[0][-1]
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(addr)
    s.listen()
    print('Listening on', addr)
    return s

def waitForConnection():
    print("Waiting for Wi-Fi connection...")
    time.sleep(10)
    retrys = retrys + 1
    if retrys >= 10:
        print("No connection found rebooting!")
        time.sleep(1)
        machine.reset() # Reboot
        
## LED #1 toggle button        
blue_btn = machine.Pin(3, machine.Pin.IN, machine.Pin.PULL_UP)
blue_last = time.ticks_ms()
        
def button_handler(pin):
    global blue_last, blue_btn
    if pin is blue_btn:
        if time.ticks_diff(time.ticks_ms(), blue_last) > 500:
            led1.toggle()
            blue_last = time.ticks_ms()      

blue_btn.irq(trigger = machine.Pin.IRQ_RISING, handler = button_handler)

# LED #1 pin
led1 = Pin(21, Pin.OUT)
led1.value(1) ## off = HIGH

# Connect to WLAN
wlan = network.WLAN(network.STA_IF)
wlan.active(True)
wlan.connect(ssid, password)

# Wait for Wi-Fi connection
while True:
    if wlan.status() >= 3:
        break
    waitForConnection()
    
# Check if connection is successful
if wlan.status() != 3:
    raise RuntimeError('Failed to establish a network connection')
    time.sleep(1)
    machine.reset() # Reboot
else:
    print('Connection successful!')
    network_info = wlan.ifconfig()
    print('IP address:', network_info[0])

## Open web socket
socket = openSocket()
retrys = 0

## Entry point
while True:
    if wlan.isconnected():
        webServer(socket)
    else:
        waitForConnection()

    
    
    