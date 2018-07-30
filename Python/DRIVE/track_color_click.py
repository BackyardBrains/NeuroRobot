# always sort import statements by length
import re
import cv2
import time
import numpy as np
from utils.player import Player
from utils.driver import Driver
from utils.detector import Detector

# retrieve colour at mouse position


def on_mouse_click(event, x, y, flags, frame):
    if event == cv2.EVENT_LBUTTONUP:
        global color, det
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        print(hsv[y-2:y+2, x-2:x+2, 0])
        # find average of 5 by 5 square around click
        h = np.median(hsv[y-2:y+2, x-2:x+2, 0])
        s = np.median(hsv[y-2:y+2, x-2:x+2, 1])
        v = np.median(hsv[y-2:y+2, x-2:x+2, 2])
        print(h, s, v)
        color = (h, s, v)
        det = Detector("color", color)


# initialize player, driver, and detector
plr = Player()
drv = Driver()
det = None

ellipse_x = 0
color = None
frame = plr.read()
cv2.imshow('frame', frame)
count = 0

while True:
    count += 1
    if count > 30:
        drv.keepAwake()

    frame = plr.read()
    if color:
        # p = size of contour, 0,1,2 is where in the screen its center is
        p0, p1, p2 = det.predict(frame)
        if max(p0,p1,p2) > 100: # if contour size is greater than 100 pixels squared
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
                    drv.forward()
                    count = 0

                time.sleep(0.1)
        else:
            drv.stop()

    else:
        # set click event for mouse to gather colour information
        cv2.setMouseCallback('frame', on_mouse_click, frame)
        cv2.imshow('frame', frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        drv.stop()
        drv.close()
        plr.close()
        break

plr.close()
drv.close()
