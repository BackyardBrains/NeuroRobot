import socket
import time
import cv2
import matplotlib.pyplot as plt
import requests
import keyboard

# takes in a string and returns its TCP message bytes
def textToMessage(text):
    return bytes([0x01,0x55]) + bytes(text, "utf-8")

TCP_IP = "192.168.100.1"
TCP_PORT = 80
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.settimeout(0.1)
s.connect((TCP_IP, TCP_PORT))

# convert key presses to TCP commands
while True:
    time.sleep(0.045)
    try: 
        if keyboard.is_pressed('w'):
            s.sendall(textToMessage("gostrait"))

        elif keyboard.is_pressed('d'):
            s.sendall(textToMessage("turnleft"))

        elif keyboard.is_pressed('a'):
            s.sendall(textToMessage("turnrite"))

        elif keyboard.is_pressed('s'):
            s.sendall(textToMessage("gorevers"))

        elif keyboard.is_pressed('r'):
            s.sendall(textToMessage("maxspeed"))

        elif keyboard.is_pressed('f'):
            s.sendall(textToMessage("minspeed"))
    except:
        s.close()
        break

cv2.destroyAllWindows()
s.close()