To run the Neurorobot App without neurorobot hardware or webcamera:
1) Get Matlab (with Image Acquisition and Image Processing toolboxes if you plan to use webcamera, Deep Learning toolbox if you plan to use object recognition, and Instrument Control toolbox if you plan to use the DIY robot with bluetooth modem)
2) Install Image Acquisition Toolbox Support Package for OS Generic Video Interface and (if needed) MATLAB Support Package for USB Webcams
3) Download/clone the Matlab directory
4) Run the script neurorobot.m (settings: camera_present = 0, use_webcam = 0, bluetooth_present = 0)

Settings to run the Neurorobot App with a webcamera: camera_present = 1, use_webcam = 1, bluetooth_present = 0
Settings to run the Neurorobot App with neurorobot hardware: camera_present = 1, use_webcam = 0, bluetooth_present = 1
