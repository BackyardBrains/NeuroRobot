<p align="center"><img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/neurorobot_drawing.jpg"></p>

# Neurorobot App

A neurorobot is a robot controlled by a computer simulation of a biological brain. At Backyard Brains we use neurorobots to teach computational neuroscience in high schools. This repository contains all the Matlab and Arduino code needed to run our neurorobots. If you haven't got a neurorobot yet, you can still run the neurorobot app using only your computer and webcamera. To learn more, explore our <a href='https://docs.google.com/document/d/12S6izB7_oZGWIqypyMhO19rSjw4mqDFAkoiaXdZETu0/edit?usp=sharing'>Remote Labs</a>, our <a href='<a href='https://docs.google.com/document/d/1_fkM_ccYyojDcovjW_f6EnSZTBed_XkrHJNA_dRZvvg/edit?usp=sharing'>User Guide</a> and our <a href='https://www.frontiersin.org/articles/10.3389/fnbot.2020.00006/full'>first publicationfirst</a>.

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
