<p align="center"><img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/neurorobot_drawing.jpg"></p>

# Neurorobot App

A neurorobot is a robot controlled by a computer simulation of a biological brain. At Backyard Brains we use neurorobots to teach computational neuroscience in high schools. This repository contains all the Matlab and Arduino code needed to run our neurorobots. If you haven't got a neurorobot yet, you can still run the neurorobot app using only your computer and webcamera. For more information, see our <a href='https://www.biorxiv.org/content/10.1101/597609v1'>first publication</a> and our <a href='https://github.com/BackyardBrains/NeuroRobot/blob/master/Documentation/Neurorobot%20User%20Guide.pdf'>neurorobot user guide</a>.

## Getting Started

Always use neurorobot.m to start the Neurorobot App and connect to your robot.

To run the Neurorobot App with the DIY robot, use these settings: 
<br>
rak_only = 0, camera_present = 1, use_webcam = 0, bluetooth_present = 1

To run the Neurorobot App with Backyard Brains' fabricated neurorobot, use these settings: 
<br>
rak_only = 1, camera_present = 1, use_webcam = 0 and bluetooth_present = 0


To run the Neurorobot App with a webcamera, use these settings:
<br>
rak_only = 0, camera_present = 1, use_webcam = 1, bluetooth_present = 0

To run the Neurorobot App without a webcamera, use these settings:
<br>
rak_only = 0, camera_present = 0, use_webcam = 0 and bluetooth_present = 0
