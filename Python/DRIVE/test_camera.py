from utils.player import Player
from utils.driver import Driver
import cv2
import time
import numpy as np
import keyboard 

drv = Driver()
plr = Player()
start = time.time()
while True:
    frame = plr.read()
    cv2.imshow('frame', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        plr.close()
        break
