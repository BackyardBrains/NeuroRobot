from utils.player import Player
from utils.driver import Driver
from utils.detector import Detector
import keyboard
import time

# initialize videoplayer, car driver, and cup detector
plr = Player()
drv = Driver()
det = Detector("hand")

while True:
    frame = plr.read()
    p0, p1, p2 = det.predict(frame)

    print("------------")
    print(p0, "|", p1, "|", p2)
    print("------------")

    # if a hand is likely >50% on screen, engage movement
    if max(p0, p1, p2) > 0.5:
        if p2 > p1 and p2 > p0:
            drv.left()
            time.sleep(0.1)
            drv.stop()
        elif p0 > p1 and p0 > p2:
            drv.right()
            time.sleep(0.1)
            drv.stop()
        else:
            drv.forward()
    else:
        drv.stop()

    if keyboard.is_pressed('q'):
        time.sleep(0.1)
        drv.stop()
        drv.close()
        plr.close()
        break

# remember to close the streams
drv.close()
plr.close()
