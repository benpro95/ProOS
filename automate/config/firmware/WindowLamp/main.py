from phew import server, connect_to_wifi
from machine import Pin
from wifi_creds import ssid, password
import ubinascii
import network
import json
import time

def button_handler(pin):
    global toggle1_last, toggle1_btn
    if pin is toggle1_btn:
        if time.ticks_diff(time.ticks_ms(), toggle1_last) > 500:
            ## toggle LED #1 power
            led1.toggle()
            toggle1_last = time.ticks_ms()   

def sendReponse(data):
    led0.value(0)
    return json.dumps({"message" : '|' + str(data) + '|'}), 200, {"Content-Type": "application/json"}

## Built-in LED
led0 = machine.Pin("LED", machine.Pin.OUT)
led0.value(1)

## LED #1 toggle button        
toggle1_btn = machine.Pin(3, machine.Pin.IN, machine.Pin.PULL_UP)
toggle1_last = time.ticks_ms()
toggle1_btn.irq(trigger = machine.Pin.IRQ_RISING, handler = button_handler)

## LED #1 pin
led1 = Pin(21, Pin.OUT)
led1.value(1) ## off = 1, on = 0

## Connect to network
network.hostname("picolamp1")
ip = connect_to_wifi(ssid, password)
mac = ubinascii.hexlify(network.WLAN().config('mac'),':').decode()
print("IP address: ", ip)
print("MAC address: ", mac)
led0.value(0)

@server.route("/api/macaddr", methods=["GET"])
def get_macaddr(request):
    return sendReponse(mac)

@server.route("/api/wl_led1toggle", methods=["GET"])
def get_led1toggle(request):
    print("toggling LED #1 power")
    led0.value(1)
    if led1.value() == 1:
        led1.value(0)
        return sendReponse(1)
    else:
        led1.value(1)
        return sendReponse(0)

@server.route("/api/wl_led1on", methods=["GET"])
def get_led1on(request):
    led0.value(1)
    print("turning LED #1 on")
    led1.value(0)
    return sendReponse(1)

@server.route("/api/wl_led1off", methods=["GET"])
def get_led1off(request):
    led0.value(1)
    print("turning LED #1 off")
    led1.value(1)
    return sendReponse(0)

@server.route("/api/wl_led1", methods=["GET"])
def get_led1(request):
    print("LED #1 status")
    led0.value(1)
    if led1.value() == 0:
        return sendReponse(1)
    else:
        return sendReponse(0)

@server.catchall()
def catchall(request):
    return json.dumps({"message" : "URL not found!"}), 404, {"Content-Type": "application/json"}

server.run()
