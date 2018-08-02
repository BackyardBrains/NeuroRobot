import PyQt5
from utils.driver import Driver
from utils.neuron import Neuron
from utils.detector import Detector
from utils.player import Player

import numpy as np
from scipy import signal
import matplotlib.pyplot as plt
import time
import keyboard
from brian2 import NeuronGroup, ms

# initialise classes
det = Detector("hand")
plr = Player()
drv = Driver()
time.sleep(0.1)
drv.lowerTurn()

## Comment to remove plottingqq
fig, ax = plt.subplots()
ax.set_ylim([-0.08,0.07])
line1, = ax.plot(np.linspace(0,10000,10000), np.zeros(10000), 'r-')
line2, = ax.plot(np.linspace(0,10000,10000), np.zeros(10000), 'b-')
line3, = ax.plot(np.linspace(0,10000,10000), np.zeros(10000), 'g-')
plt.show(block=False)
fig.canvas.draw()
## /Comment to remove plotting

# Izhikevitch Neuron Model from http://brian2.readthedocs.io/en/stable/introduction/brian1_to_2/library.html
eqs = '''dv/dt = (0.04*active/ms/mV + 0.04/ms/mV)*v**2+(5/ms)*v+130*mV/ms-w + I : volt (unless refractory)
         dw/dt = (0.02/ms)*((0.2/ms)*v-w) : volt/second
         active : 1
         I : volt/second'''


nrn_left = Neuron(NeuronGroup(1, eqs, threshold='v > 50*mV', reset='v = -50*mV', refractory=10*ms, method='rk2'))
nrn_center = Neuron(NeuronGroup(1, eqs, threshold='v > 50*mV', reset='v = -50*mV', refractory=10*ms, method='rk2'))
nrn_right = Neuron(NeuronGroup(1, eqs, threshold='v > 50*mV', reset='v = -50*mV', refractory=10*ms, method='rk2'))


left = 0
right = 0
center = 0

# drv.raiseSpeed()
pip_1 = np.array(np.concatenate([np.zeros(1000), np.ones(5)*32000, np.ones(5)*32000, np.ones(5)*32000, np.zeros(1000)]), dtype=np.int16)
pip_2 = np.array(np.concatenate([np.zeros(1000), np.ones(10)*32000, np.ones(10)*-32000, np.ones(10)*32000, np.zeros(1000)]), dtype=np.int16)
pip_3 = np.array(np.concatenate([np.zeros(1000), np.ones(5)*-32000, np.ones(5)*32000, np.ones(5)*-32000, np.zeros(1000)]), dtype=np.int16)
fs = 44100

while True:
    frame = plr.read()
    # get size and position of biggest colour splotch
    p2, p1, p0 = det.predict(frame)
    if max(p0, p1, p2) < 0.87:  # too small
        p0 = p1 = p2 = 0
        drv.stop()

    # add them to counters
    left += (10e-2 * p0)
    center += (10e-2 * p1)
    right += (10e-2 * p2)

    left_spikes = nrn_left.update(left, pip=pip_1, fs=fs)
    center_spikes = nrn_center.update(center, pip=pip_2, fs=fs)
    right_spikes = nrn_right.update(right, pip=pip_3, fs=fs)

    if right_spikes or left_spikes or center_spikes:  # reset on spike
        left = center = right = 0
    print(p0, p1, p2)
    print("Left Spikes: ", left_spikes, "Center Spikes: ", center_spikes,
          "Right Spikes: ", right_spikes)

    ## Comment to remove plotting
    line1.set_ydata(nrn_left.history(10000))  # update line data
    line2.set_ydata(nrn_center.history(10000))
    line3.set_ydata(nrn_right.history(10000))
    ax.draw_artist(line1)  # redraw line
    ax.draw_artist(line2)
    ax.draw_artist(line3)
    plt.pause(0.001)  # push the update
    ## /Comment to remove plotting

    ## Comment to remove driving
    if right_spikes > left_spikes and right_spikes > center_spikes:
        drv.right()

    elif left_spikes > right_spikes and left_spikes > center_spikes:
        drv.left()

    elif center_spikes > left_spikes and center_spikes > right_spikes:
        drv.forward()
    ## /Comment to remove driving

    else:
        drv.stop()

    if keyboard.is_pressed('q'):
        time.sleep(0.2)
        drv.stop()
        time.sleep(0.2)
        drv.close()
        plr.close()
        break
