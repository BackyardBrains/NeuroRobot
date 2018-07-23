import cv2
import requests
import time
from imutils.video import FileVideoStream

r1 = requests.get(
    "http://192.168.100.1/server.command?command=set_resol&type=h264&pipe=0&value=2", auth=("admin", "admin"))
r2 = requests.get(
    "http://192.168.100.1/server.command?command=set_enc_quality&type=h264&pipe=0&value=32", auth=("admin", "admin"))
r3 = requests.get(
    "http://192.168.100.1/server.command?command=set_max_fps&type=h264&pipe=0&value=500", auth=("admin", "admin"))
# r4 = requests.get(
#     "http://192.168.100.1/server.command?command=set_gop&type=h264&pipe=0&value=50", auth=("admin", "admin"))
cap = cv2.VideoCapture("rtsp://admin:admin@192.168.100.1/cam1/h264")
cap.set(cv2.CAP_PROP_BUFFERSIZE, 0)

while True:
    ret, frame = cap.read()
    cv2.imshow('frame', frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        cap.release()
        cv2.destroyAllWindows()
        break