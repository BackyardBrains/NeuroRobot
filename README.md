# NeuroRobot app by Backyard Brains
<b>Updates</b><br>
<b>2023-03-24</b>. SpikerBot 2.0. ML Experiment support. Webcam support. Requires Windows or Matlab.<br>
<b>2022-12-12</b>. The NeuroRobot app <b>Windows Installer</b> is now (somewhat) stable! To use it, download the repo, unpack SpikerBot_Installer.zip (several layers deep), and install the SpikerBot app on your Windows machine. Because this is an unsigned app, you will need to navigate a blue warning message by clicking 'More info' then 'Run Anyway' in order to install the app. Please note that webcam mode/Computer with Camera is not supported in the compiled app.<br>
<br>
<b>Summary</b><br>
A <b>neurorobot</b> is a robot controlled by a computer model of a biological brain. <a href="https://github.com/BackyardBrains">Backyard Brains</a> is developing a neurorobot for education that enables students to perform computational neuroscience investigations by designing brains and observing their behavior (<a href="https://www.frontiersin.org/articles/10.3389/fnbot.2020.00006/full">Harris et al., 2020</a>). Students use the <b>NeuroRobot app</b> to design and simulate biologically-based neural networks connected to mobile robots with sensors (camera, microphone, distance sensor) and actuators (speaker, motors, lights).<br>
<br>
<p align="center"><img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/robots.jpg" width="800"></p>
<br>
<b>How the app works</b><br>
The NeuroRobot app has 3 modes of operation: Startup, Runtime and Design. <b>Startup</b> is the main menu. <b>Runtime</b> is the brain simulation engine where you can see what the brain is observing, hearing and doing. This is also where you provide dopamine rewards to modulate its motivation and learning. <b>Design</b> is where you modify the structure of the brain. Click anywhere in the brain-shaped area to add a neuron or synapse. Select the orange box next to the eyes, microphone or whiskers to send sensory information to specific neurons in the brain. Select a neuron and click the ‘Axon’ button to extend an axon to the wheels, the speaker or another neuron.
<br>
<br>
<p align="center"><b>Runtime</b><br>
<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/ux_runtime.jpg" width="800"></p>
<br>
The simulated neurons are designed to model the spiking (aka firing) of biological neurons. Thus, they can be quiet or fire regularly or in bursts, and can respond in different ways to different synaptic inputs. Synaptic connections between neurons have a “weight” (-100 to 100 mV) that represents the strength of the synapse. Every time a sending (“presynaptic”) neuron fires a spike, the weight of the synapse is applied to the receiving (“postsynaptic”) neuron’s membrane potential. To reliably trigger a spike, a synapse should have a weight of 25 mV or more. To test this, connect a highly active neuron to several quiet neurons, use different synaptic weights, and examine the different rates of spiking produced.
<br>
<br>
<p align="center"><b>Design</b><br>
<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/ux_design.jpg" width="600"></p>
<br>
Synaptic connections can be plastic. This means that if a sending and a receiving neuron are active at the same time, a synapse connecting them will grow stronger. In other words, neurons that fire together, wire together. Some synapses are plastic only in the presence of a dopamine reward.<br>
<br>
The NeuroRobot app collects camera and microphone data continuously. Within this data, it can detect simple features such as color and pitch, and complex data such as objects and words. To make a neuron respond to a sensory feature, select the orange square next to the relevant sensor, then select the target neuron. To make a neuron produce movement or sound, select the neuron first, then the orange square of the desired speaker or motor.<br>
<br>
<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/brains.jpg">
<br>
The basal ganglia allows vertebrate organisms to select particular actions in particular situations. Specifically, the basal ganglia disinhibits (i.e. activates) one group of neurons, associated with one specific behavior, at a time. Dopamine rewards make the currently selected basal ganglia neuron group and its associated behavior stay selected longer (higher "motivation") and increases their likelihood of being selected in similar situations in the future. Inputs to basal ganglia neurons strongly influence how long the currently selected neuronal group stays selected. Neurons belonging to a particular basal ganglia group are identified by the “ID” variable, by dashed lines emanating from "Striatal" neurons, and (optionally) by color.
<br>
<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/logo.jpg" width="480" align="right">
