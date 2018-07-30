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
det = Detector("color", "cyan")

path = []
count = 0
while True:
    count += 1
    if count > 30: # keep tcp from dying
        drv.keepAwake()

    frame = plr.read()
    # p = size of contour, 0,1,2 is where in the screen its center is
    p0, p1, p2 = det.predict(frame) 
    print(p0, p1, p2)
    if max(p0,p1,p2) > 100: # if contour size is greater than 100 pixels squared
        if p2 > p1:
            drv.right()
            time.sleep(0.1)
            drv.stop()
            count = 0
            path.append(-1)


        elif p0 > p1:
            drv.left()
            time.sleep(0.1)
            drv.stop()
            count = 0
            path.append(1)


        else:
            count = 0
            drv.forward()
            path.append(0)

    else:
        drv.stop()

    if keyboard.is_pressed('q'):
        np.save("path", np.asarray(path))
        drv.stop()
        drv.close()
        plr.close()
        break

plr.close()
drv.close()
