from utils.player import Player
from utils.driver import Driver
from utils.detector import Detector

# initialize videoplayer, car driver, and cup detector
plr = Player()
drv = Driver()
det = Detector("cup")

while True:
    ret, frame = plr.read()
    p0, p1, p2 = det.predict(frame)

    print("------------")
    print(p0, "|", p1, "|", p2)
    print("------------")

    # if a cup is likely >50% on screen, engage movement
    if max(p0, p1, p2) > 0.5:
        if p2 > p1 and p2 > p0:
            drv.right()
        elif p0 > p1 and p0 > p2:
            drv.left()
        else:
            drv.forward()

# remember to close the streams
drv.close()
plr.close()
