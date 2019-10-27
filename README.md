<p align="center"><img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/neurorobot_drawing.jpg"></p>

# Neurorobot App

A neurorobot is a robot controlled by a computer simulation of a biological brain. At Backyard Brains we use neurorobots to teach computational neuroscience in high schools. This repository contains all the Matlab and Arduino code needed to run our neurorobots. If you haven't got a neurorobot yet, you can still run the neurorobot app using only your computer and webcamera. For more information, see https://www.biorxiv.org/content/10.1101/597609v1

## Getting Started

To run the Neurorobot App without a neurorobot or a webcamera:
<ul>
<li>Get Matlab with the Image Processing toolbox
<li>Run neurorobot.m with these settings: rak_only = 0, camera_present = 0, use_webcam = 0 and bluetooth_present = 0
</ul>

To run the Neurorobot App with Backyard Brains' fabricated neurorobot hardware
<ul>
<li>Get Matlab
<li>Run neurorobot.m with these settings: rak_only = 1, camera_present = 1, use_webcam = 0 and bluetooth_present = 0
</ul>

To run the Neurorobot App with Backyard Brains' DIY robot:
<ul>
<li>Get Matlab with the Instrument Control toolbox to connect to the robot's bluetooth modem
<li>Run neurorobot.m with these settings: rak_only = 0, camera_present = 1, use_webcam = 0, bluetooth_present = 1
</ul>

To run the Neurorobot App with a webcamera
<ul>
<li>Get Matlab with the Image Acquisition toolbox
<li>Install Image Acquisition Toolbox Support Package for OS Generic Video Interface and (if needed) MATLAB Support Package for USB Webcams
<li>Run neurorobot.m with these settings: rak_only = 0, camera_present = 1, use_webcam = 1, bluetooth_present = 0
</ul>

Also - to use object recognition functionality:
<ul>
<li>Get the Deep Learning toolbox
<li>Install the Deep Learning Toolbox Model for GoogLeNet Network Add-On
</ul>

## Neurorobot Data
<p align="center"><img src="https://github.com/BackyardBrains/NeuroRobot/blob/develop-rak5270/Matlab/ontimes.jpg"></p>
