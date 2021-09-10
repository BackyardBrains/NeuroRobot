# NeuroRobot app by Backyard Brains

A neurorobot is a robot controlled by a computer simulation of a biological brain. At Backyard Brains we use neurorobots to teach computational neuroscience in high schools. This repo contains all the Matlab and C/C++ code needed to run the NeuroRobot app, with or without a robot. The app allows you to design and simulate biologically-based neural networks connected to sensors (camera, microphone, distance sensor) and effectors (speaker, motors).

<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/robots.jpg">

# Get Started

The following setup is recommended:

- Matlab 2020a or later (iOS beta <a href="https://testflight.apple.com/join/N41wWHyJ">here</a>)
- Image Processing Toolbox (for vision)
- Digital Signal Processing Toolbox (for hearing)
- Image Acquisition Toolbox (for webcam-vision, <a href="https://www.mathworks.com/matlabcentral/fileexchange/45183-image-acquisition-toolbox-support-package-for-os-generic-video-interface">this support package</a> is also needed)
- Audio Toolbox (for webcam-hearing)
- Deep Learning Toolbox and Paralell Computing Toolbox (for object detection, <a href="https://www.mathworks.com/help/deeplearning/ref/alexnet.html">AlexNet</a> and <a href="https://www.mathworks.com/help/deeplearning/ref/googlenet.html">GoogLeNet</a> add-ons are also needed)
- Comic Book font (find Comic_Book.ttf in the NeuroRobotToolbox folder; in Windows, right-click the file and choose ‘Install for All Users’; on Mac, double-click the file and select ‘Install Font’; restart Matlab)
- Work with colorful objects in brightly lit rooms for optimal colorvision

To start the NeuroRobot app, open the file NeuroRobotToolbox/neurorobot.m in Matlab, adjust <a href="https://docs.google.com/document/d/1_fkM_ccYyojDcovjW_f6EnSZTBed_XkrHJNA_dRZvvg/edit#bookmark=kix.lcvfd1hyq9l0">settings</a>, then run the file. This launches the app’s Startup menu.

Please see the <a href='https://docs.google.com/document/d/1_fkM_ccYyojDcovjW_f6EnSZTBed_XkrHJNA_dRZvvg/edit?usp=sharing'>User Guide</a> for more information about getting started with the NeuroRobot app in Matlab.

# Design Brains

<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/brains.jpg">

Many neurons in the NeuroRobot app are Izhikevich neurons designed to simulate the spiking patterns of biological neurons. These neurons can be quiet, fire regularly or in bursts, and can respond to inputs in different ways. Synaptic connections between neurons have a strength (“weight”) between -100 and 100 mV. Every time a sending (“presynaptic”) neuron fires a spike, the weight of the synapse is applied to the receiving (“postsynaptic”) neuron. To reliably trigger a spike in a neuron, the incomming synapse spike should have a strength of 25 mV or more. To test this, connect a highly active neuron to several quiet neurons, use a range of synaptic weights, and examine the effect on the postsynaptic neurons.

Synaptic connections can be plastic. This means that if a sending and a receiving neuron are active at the same time, a synapse connecting them will grow stronger. In other words, neurons that fire together, wire together. Some synapses are plastic only in the presence of a dopamine reward.

The NeuroRobot app collects camera and microphone data continuously. Within this data, it can detect simple features such as color and pitch, and complex data such as objects and words. To make a neuron respond to a sensory feature, select the orange square next to the relevant sensor, then select the target neuron. To make a neuron produce movement or sound, select the neuron first, then the orange square of the desired speaker or motor.

The basal ganglia allows vertebrate organisms to select particular actions in particular situations. Specifically, the basal ganglia disinhibits (i.e. activates) one group of neurons, associated with one specific behavior, at a time. Dopamine rewards make the currently selected basal ganglia neuron group and its associated behavior stay selected longer (higher "motivation") and increases their likelihood of being selected in similar situations in the future. Inputs to basal ganglia neurons strongly influence how long the currently selected neuronal group stays selected. Neurons belonging to a particular basal ganglia group are identified by the “ID” variable, by dashed lines emanating from "Striatal" neurons, and (optionally) by color.

Please refer to the <a href='https://docs.google.com/document/d/12S6izB7_oZGWIqypyMhO19rSjw4mqDFAkoiaXdZETu0/edit'>Labs and lesson plans</a> for more information about designing brains in the NeuroRobot app.

# Troubleshooting

In the Startup menu, click Connect. The Connect button should turn green in 5-20 s. If the button turns red or Matlab crashes, you have a problem. Try restarting Matlab. If you have a robot, make sure the WiFi connection is intact. If you are using a computer with a webcamera, use the 'ver' command to confirm that you have the Image Acquisition Toolbox installed, use the Matlab Add-on Explorer to check that the Support Package for OS Generic Video Interface is installed, and confirm that the ‘rak_cam = videoinput('winvideo', 1); preview(rak_cam)’ command is able to display video from your webcamera.

# Further Reading

<a href='https://docs.google.com/document/d/1_fkM_ccYyojDcovjW_f6EnSZTBed_XkrHJNA_dRZvvg/edit?usp=sharing'>User Guide</a><br>
<a href='https://docs.google.com/document/d/12S6izB7_oZGWIqypyMhO19rSjw4mqDFAkoiaXdZETu0/edit?usp=sharing'>Lesson Plans</a><br>
<a href='https://www.frontiersin.org/articles/10.3389/fnbot.2020.00006/full'>2020 paper</a><br>
<a href='https://www.biorxiv.org/content/10.1101/2021.04.01.438071v2'>2021 preprint</a><br>

<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/logo.jpg" width="480">
