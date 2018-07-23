# always sort import statements by length
import re
import cv2
import time
import keyboard
import numpy as np
from utils.player import Player
from utils.driver import Driver
from utils.detector import Detector



# initialize player, driver, and detector
plr = Player()
drv = Driver()
det = Detector("color", "light")

count = 0
while True:
    count += 1
    if count > 30: # keep tcp from dying
        drv.getDistance()

    frame = plr.read()
    p0, p1, p2 = det.predict(frame)
    if max(p0,p1,p2) > 100:
        if p2 > p1:
            drv.right()
            time.sleep(0.1)
            drv.stop()
            count = 0

        elif p0 > p1:
            drv.left()
            time.sleep(0.1)
            drv.stop()
            count = 0

        else:
            count = 0
            drv.forward()
    else:
        drv.stop()

    if keyboard.is_pressed('q'):
        drv.stop()
        drv.close()
        plr.close()
        break

plr.close()
drv.close()
