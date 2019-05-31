To run the Neurorobot App without neurorobot hardware or webcamera:

• Get Matlab with the Image Processing toolbox (also the Deep Learning toolbox if you plan to use object recognition)
• Download/clone the Matlab directory
• Run the script neurorobot.m with settings rak_only = 0, camera_present = 0, use_webcam = 0 and bluetooth_present = 0

To run the Neurorobot App with a DIY robot
Instrument Control toolbox if you plan to use a DIY robot with a bluetooth modem

Settings to run the Neurorobot App with a webcamera: camera_present = 1, use_webcam = 1, bluetooth_present = 0
Settings to run the Neurorobot App with neurorobot hardware: camera_present = 1, use_webcam = 0, bluetooth_present = 1

2)also Image Acquisition toolbox if you plan to use a webcamera rather than a robot,  Install Image Acquisition Toolbox Support Package for OS Generic Video Interface and (if needed) MATLAB Support Package for USB Webcams
