import socket
import time
import re

class Driver(object):

    # initialise tcp connection with RAK
    def __init__(self):
        self.tcp_ip = "192.168.100.1"
        self.tcp_port = 80
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((self.tcp_ip, self.tcp_port))
        self.delay = 0.01
        self.clock = time.time()
        self.last_distance = 9999

        time.sleep(0.1)
        self.s.sendall(self.textToMessage("minspeed"))
        time.sleep(0.1)
        self.s.sendall(self.textToMessage("minspeed"))
        time.sleep(0.1)
        self.s.sendall(self.textToMessage("minturns"))
        time.sleep(0.1)
        self.s.sendall(self.textToMessage("minturns"))

    def checkClock(self): # make sure were not overloading TCP
        curr_time = time.time()
        # print(curr_time - self.clock)
        if curr_time - self.clock >= self.delay:
            self.clock = curr_time
            return True
        else:
            return False

    # helper function, convert string to bytes packet to send to RAK
    def textToMessage(self, text):
        # packet must be padded with [0x01,0x55] to be accepted by RAK
        return bytes([0x01,0x55]) + bytes(text, "utf-8")
    
    def left(self, iterations=1):
        if self.checkClock():
            self.s.send(self.textToMessage("turnleft"))

    def right(self, iterations=1):
        if self.checkClock():
            self.s.send(self.textToMessage("turnrite"))

    def forward(self, iterations=1):
        if self.checkClock():
            self.s.send(self.textToMessage("gostrait"))

    def reverse(self, iterations=1):
        if self.checkClock():
            self.s.send(self.textToMessage("gorevers"))

    def stop(self, iterations=1):
        if self.checkClock():
            self.s.send(self.textToMessage("stopmove"))

    def lowerSpeed(self, iterations=1):
        if self.checkClock():
            self.s.send(self.textToMessage("minspeed"))

    def raiseSpeed(self, iterations=1):
        if self.checkClock():
            self.s.send(self.textToMessage("maxspeed"))

    def lowerTurn(self, iterations=1):
        if self.checkClock():
            self.s.send(self.textToMessage("minturns"))

    def raiseTurn(self, iterations=1):
        if self.checkClock():
            self.s.send(self.textToMessage("maxturns"))


    # receve distance measure from ultrasonic sensors
    def getDistance(self, delay=0.3):
        dist = str(self.s.recv(1024), 'utf-8') # read 1024 bits as string
        # print(dist)
        if dist:
            dist = dist.split("\n")[-2]
            dist = ''.join([i for i in dist if i.isdigit()]) # get last number collected from serial
            if len(dist) <= 5:
                self.last_distance = int(dist)
                return int(dist)
                
        return self.last_distance

    def close(self):
        time.sleep(0.3)
        self.stop()
        time.sleep(0.1)
        self.s.close()
