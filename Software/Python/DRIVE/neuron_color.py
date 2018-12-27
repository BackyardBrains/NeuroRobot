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
# drv = Driver()
det = Detector("color", "orange")
plr = Player()

## Comment to remove plotting
fig, ax = plt.subplots()
ax.set_ylim([-0.08,0.07])
line1, = ax.plot(np.linspace(0,10000,10000), np.zeros(10000), 'r-')
line2, = ax.plot(np.linspace(0,10000,10000), np.zeros(10000), 'b-')
line3, = ax.plot(np.linspace(0,10000,10000), np.zeros(10000), 'g-')
## /Comment to remove plotting

plt.show(block=False)
fig.canvas.draw()

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

# create 'pips', sounds to play when neuron is spiking
pip_1 = np.array(np.concatenate([np.zeros(1000), np.ones(10)*32000, np.ones(10)*-32000, np.ones(10)*32000, np.zeros(1000)]), dtype=np.int16)
pip_2 = np.array(np.concatenate([np.zeros(1000), np.ones(5)*32000, np.ones(5)*32000, np.ones(5)*32000, np.zeros(1000)]), dtype=np.int16)
pip_3 = np.array(np.concatenate([np.zeros(1000), np.ones(5)*-32000, np.ones(5)*32000, np.ones(5)*-32000, np.zeros(1000)]), dtype=np.int16)
fs = 44100

def limit(x): # limits x to be between 0 and 1
    return max(min(x,1),0)


while True:
    frame = plr.read()
    # get size and position of biggest colour splotch
    p0, p1, p2 = det.predict(frame)
    if max(p0, p1, p2) < 50000:  # too small
        p0 = p1 = p2 = 0
    # add them to counters
    left += np.log(1 + p0) * np.random.rand() / 200
    center += np.log(1 + p1) * np.random.rand() / 200
    right += np.log(1 + p2) * np.random.rand() / 200

    left_spikes = nrn_left.update(left, pip=pip_1, fs=fs)
    center_spikes = nrn_center.update(center, pip=pip_2, fs=fs)
    right_spikes = nrn_right.update(right, pip=pip_3, fs=fs)

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

    if left_spikes or center_spikes or right_spikes:
        left = right = center = 0

    ## Comment to remove driving
    # if right_spikes > left_spikes:
    #     drv.right(1)
    #     activate = 0
    #     count = 0
    # elif left_spikes > right_spikes:
    #     drv.left(1)
    #     count -= 10
    #     deactivate = 0
    # else:
    #     drv.forward(1)
    ## /Comment to remove driving

    if keyboard.is_pressed('q'):
        # time.sleep(0.2)
        # drv.stop()
        # time.sleep(0.2)
        # drv.close()
        plr.close()
        break
