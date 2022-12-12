# NeuroRobot app by Backyard Brains
<b>Updates</b><br>
<i>2022-12-12</i><br>
The NeuroRobot app <b>Windows Installer</b> is now (somewhat) stable! To use it, download the repo, unpack 'SpikerBot_Installer.zip' (several layers deep), and install the SpikerBot app on your Windows machine. Because this is an unsigned app, you will need to navigate a blue warning by clicking 'More info' then 'Run Anyway' in order to install the app. Please note that webcam mode/Computer with Camera is not supported in the compiled app.<br>
<br>
<b>Summary</b><br>
A <b>neurorobot</b> is a robot controlled by a computer model of a biological brain. <a href="https://github.com/BackyardBrains">Backyard Brains</a> is developing a neurorobot for education that enables students to perform advanced computational neuroscience investigations by designing brains and observing their activity and robot behavior (<a href="https://www.frontiersin.org/articles/10.3389/fnbot.2020.00006/full">Harris et al., 2020</a>). Students use this <b>NeuroRobot app</b> to design and simulate biologically-based neural networks connected to mobile robots with sensors (camera, microphone, distance sensor) and effectors (speaker, motors, lights).<br>
<br>
<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/robots.jpg"><br>
<br>
<b>How the app works</b><br>
Many neurons in the NeuroRobot app are Izhikevich neurons designed to simulate the spiking patterns of biological neurons. These neurons can be quiet, fire regularly or in bursts, and can respond to inputs in different ways. Synaptic connections between neurons have a strength (“weight”) between -100 and 100 mV. Every time a sending (“presynaptic”) neuron fires a spike, the weight of the synapse is applied to the receiving (“postsynaptic”) neuron. To reliably trigger a spike in a neuron, the incomming synapse spike should have a strength of 25 mV or more. To test this, connect a highly active neuron to several quiet neurons, use a range of synaptic weights, and examine the effect on the postsynaptic neurons.<br>
<br>
Synaptic connections can be plastic. This means that if a sending and a receiving neuron are active at the same time, a synapse connecting them will grow stronger. In other words, neurons that fire together, wire together. Some synapses are plastic only in the presence of a dopamine reward.<br>
<br>
<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/brains.jpg"><br>
<br>
The NeuroRobot app collects camera and microphone data continuously. Within this data, it can detect simple features such as color and pitch, and complex data such as objects and words. To make a neuron respond to a sensory feature, select the orange square next to the relevant sensor, then select the target neuron. To make a neuron produce movement or sound, select the neuron first, then the orange square of the desired speaker or motor.<br>
<br>
The basal ganglia allows vertebrate organisms to select particular actions in particular situations. Specifically, the basal ganglia disinhibits (i.e. activates) one group of neurons, associated with one specific behavior, at a time. Dopamine rewards make the currently selected basal ganglia neuron group and its associated behavior stay selected longer (higher "motivation") and increases their likelihood of being selected in similar situations in the future. Inputs to basal ganglia neurons strongly influence how long the currently selected neuronal group stays selected. Neurons belonging to a particular basal ganglia group are identified by the “ID” variable, by dashed lines emanating from "Striatal" neurons, and (optionally) by color.<br>
<br>
<img src="https://github.com/BackyardBrains/NeuroRobot/blob/master/Gallery/logo.jpg" width="480" align="right"><br>
<br>
