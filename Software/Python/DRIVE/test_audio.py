import av
import time
import numpy as np
import sounddevice as sd
from utils.player import Player

plr = Player()

cap = av.open("rtsp://admin:admin@192.168.100.1/cam1/h264")
stream = [s for s in cap.streams][1] # set stream to video stream, [1] is audio stream

for packet in cap.demux(stream):
    for frame in packet.decode(): # rate is 8000
        audio = np.frombuffer(frame.planes[0], dtype=np.int16)
        butter = np.array([1, -1, 1, -1,1, -1, 1, -1])
        audio = np.array(np.convolve(audio, butter, mode="same"),dtype=np.int16)
        # print(audio)
        if audio is not None:
            sd.play(audio, 8000)
print("Done")