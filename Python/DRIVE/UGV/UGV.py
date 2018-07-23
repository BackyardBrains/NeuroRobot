import cv2
import time
import socket
import requests
import keyboard
import matplotlib.pyplot as plt


# takes in a string and returns its TCP message bytes
def textToMessage(text):
    return bytes([0x01,0x55]) + bytes(text, "utf-8")

# set up IP conection to RAK camera
r1 = requests.get(
    "http://192.168.100.1/server.command?command=set_resol&type=h264&pipe=0&value=1", auth=("admin", "admin"))
r2 = requests.get(
    "http://192.168.100.1/server.command?command=set_enc_quality&type=h264&pipe=0&value=32", auth=("admin", "admin"))
r3 = requests.get(
    "http://192.168.100.1/server.command?command=set_max_fps&type=h264&pipe=0&value=60", auth=("admin", "admin"))
r4 = requests.get(
    "http://192.168.100.1/server.command?command=set_gop&type=h264&pipe=0&value=100", auth=("admin", "admin"))
cap = cv2.VideoCapture("rtsp://admin:admin@192.168.100.1/cam1/h264")

TCP_IP = "192.168.100.1" 
TCP_PORT = 80
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((TCP_IP, TCP_PORT))

# convert key presses to TCP commands
while True:

    # elapsed time determines if command can be sent again, combat buffer overflow
    ret, frame = cap.read()
    cv2.imshow('frame', frame)

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
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        cap.release()
        cv2.destroyAllWindows()
        s.close()
        break

cap.release()
cv2.destroyAllWindows()
s.close()