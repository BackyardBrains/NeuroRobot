"Here ye, here ye.
Beware, all who wander this code are lost."

This is less an instruction manual, and more just a list of warnings.

info: OpenCV leads to a video delay of 0.8 seconds, PyAV is 0.38 seconds, both are between 15 and 20fps. Improvements can definitely be made.


CONTAINS
----------------------------------------------
Python/ contains the applications I wrote; Arduino/Drive_From_Rak_No_Stop
contains the code to be uploaded to the board. 

Neurorobot/DRIVE/ contains all the interesting programs, in particular the
color tracking and object tracking applications.

Neurorobot/DRIVE/utils contains all the underlying interface with the RAK 5206
wifi chip, as well as numerous functions used in DRIVE.

DRIVE/UGV contains legacy code

Neurorobot/ML/ contains how I trained the nets for DRIVE. It is relatively
self explanatory. Put images into Train and Validate and run 
InceptionTuner_Cup.py or InceptionTuner_Hand.py. The window test is a way
to visualize what the car will see using your laptop's webcam.

Recommendations for Training:
- Training sets should be high quality, but don't have to be that large, 
anywhere > 200 images should be fine, keep number of images in both classes
about equal so you don't underfit
- Epochs > 150 doesn't really do anything, > 100 is recommended however
- Having a GPU helps a lot, but training is theoretically possible on CPU 
since the image number is small
- Images must be 150x150 unless you change the net architecture


LIST OF WHAT DO
----------------------------------------------
utils/detector.py - object for processing video frames and spiting out info 
	about them (i.e position and probability of detected hand)
utils/driver.py - object for communicating with RAK 5206 and arduino to drive
	robot motors
utils/modeler.py - helper object for detector.py, creates and loads neural net
utils/neuron.py - object for creation of neuron/neurongroup using brian2
utils/player.py - object for communcating with RAK 5206 to get video frames

DOWNLOAD_MODELS.py - download inception models for first time
neuron_color.py - spiking neurons sensitive to color and position
neuron_distance.py - spiking neurons sensitive to ultrasonic sensor data
neuron_hand.py - spiking neurons sensitive to hand
STOP.py - stop the car from moving, used to stop rogue bot
test_audio.py - experiment to grab audio from microphone on bot; crashes
test_camera.py - test and display camera feed if it is working
track_color_click.py - drive and follow coloured object after it is clicked 
	via mouse on the open imshow window
track_color.py - drive and follow coloured object as described in code
track_cup.py - drive and follow cup based off keras model
track_hand.py - drive and follow hand based off keras model


INSTALLATION
----------------------------------------------
Everything in this project is currently operational on my Dell XPS 13 running
Ubuntu 16.0.4 LTS. I personally use a virtual env for tensorflow and keras.

All package requirements are in requirements.txt, not all of them are needed
but this is a working pip freeze of my current environment.

I am currently running Python 3.5.2, there is no reason other versions of 
python shouldn't work, but who knows.

WARNING: ffmpeg version 3 DOES NOT WORK with PyAV, you must install the
version 2 branch, (version 2.8.15 Feynman works perfectly). 
https://www.ffmpeg.org/download.html#releases


RUNNING
----------------------------------------------
'python3 DRIVE/anything-in-drive.py' will typically run any app.

- On ubuntu you MUST be root to use the keyboard package, non-root cannot read
keyboard strokes (use sudo su -p) 
- Q will stop most programs
- Ctrl-C will stop anything
- before object tracking, you must download the necessary pretrained models,
run DOWNLOAD_MODELS.py while on an active internet connection. This only
has to be done once
- if theres nothing but a black screen from the video feed this means no valid
frames have been read
- if the car has gone AWOL run 'python3 DRIVE/STOP.py'


THINGS YOU SHOULD BE SCARED OF
----------------------------------------------
- Don't forget to close streams and RTSP connections, or else the camera will 
refuse to connect and stream data
- Don't send too many TCP commands, there's a reason my functions check if a
time requirement since last TCP command has been fulfilled, the RAK will drop
connection if this is abused
- Don't put the batteries in backwards
- Don't assume you have the real current frame; sometimes no frames have been 
received so you'll just retrieve the previous frame from read()
- INITIALISE Driver OBJECT AFTER Detector OBJECT OR ELSE IT'LL TIME OUT
-Ilya


