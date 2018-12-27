import sys
import threading
import time

import av
import cv2
import numpy as np
import requests
from PIL import Image


class Player(object):

    # initialise video stream from RAK, set quality values
    def __init__(self, res=2, qual=32, fps=25, gop=100):
        r1 = requests.get( # set resolution
            "http://192.168.100.1/server.command?command=set_resol&type=h264&pipe=0&value=" + str(res), auth=("admin", "admin"))
        r2 = requests.get( # set quality of image
            "http://192.168.100.1/server.command?command=set_enc_quality&type=h264&pipe=0&value=" + str(qual), auth=("admin", "admin"))
        r3 = requests.get( # set fps
            "http://192.168.100.1/server.command?command=set_max_fps&type=h264&pipe=0&value=" + str(fps), auth=("admin", "admin"))
        r4 = requests.get( # set gop
            "http://192.168.100.1/server.command?command=set_gop&type=h264&pipe=0&value=" + str(gop), auth=("admin", "admin"))

        (width, height) = [(320,240),(640,480),(1280,720)][res] # select corresponding dimensions
        self.current_image = np.zeros((height,width,3), np.uint8) # initialise to black screen
        self.kill_thread = False
        self.t = threading.Thread(target=self.frameGrabber) # start thread for recieving video
        self.t.start()

    def frameGrabber(self):
        cap = av.open("rtsp://admin:admin@192.168.100.1/cam1/h264")
        stream = [s for s in cap.streams][0] # set stream to video stream, [1] is audio stream

        for packet in cap.demux(stream):
            for frame in packet.decode():
                img = np.array(frame.to_image())

                # convert frame to BGR for opencv
                img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
                self.current_image = img
                
                # kill thread if signal is active
                if self.kill_thread:
                    return

    # returns current frame
    def read(self):
        return self.current_image

    def close(self):
        cv2.destroyAllWindows()
        self.kill_thread = True
