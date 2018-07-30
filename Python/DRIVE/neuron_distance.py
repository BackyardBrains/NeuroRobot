
import PyQt5
from utils.driver import Driver
from utils.neuron import Neuron
import numpy as np
from scipy import signal
import matplotlib.pyplot as plt
import time
import keyboard
from brian2 import NeuronGroup, ms

## Comment to remove plotting
fig, ax = plt.subplots()
ax.set_ylim([-0.08,0.07])
line1, = ax.plot(np.linspace(0,10000,10000), np.zeros(10000), 'r-')
line2, = ax.plot(np.linspace(0,10000,10000), np.zeros(10000), 'b-')
plt.show(block=False)
fig.canvas.draw()
## /Comment to remove plotting

drv = Driver()

eqs_1 = '''dv/dt = (0.04*active/ms/mV + 0.04/ms/mV)*v**2+(5/ms)*v+130*mV/ms-w + I : volt (unless refractory)
         dw/dt = (0.02/ms)*((0.2/ms)*v-w) : volt/second
         active : 1
         I : volt/second'''

eqs_2 = '''dv/dt = (0.04*active/ms/mV + 0.04/ms/mV)*v**2+(5/ms)*v+140*mV/ms-w + I : volt (unless refractory)
         dw/dt = (0.02/ms)*((0.2/ms)*v-w) : volt/second
         active : 1
         I : volt/second'''

nrn_1 = Neuron(NeuronGroup(1, eqs_1, threshold='v > 50*mV', reset='v = -50*mV', refractory=10*ms, method='rk2'))
nrn_2 = Neuron(NeuronGroup(1, eqs_2, threshold='v > 50*mV', reset='v = -70*mV', refractory=5*ms, method='rk2'))
activate = 0 
deactivate = 0

drv.raiseSpeed()
# create 'pips', sounds to play when neuron is spiking
pip_1 = np.array(np.concatenate([np.zeros(1000), np.ones(5)*32000, np.ones(5)*32000, np.ones(5)*32000, np.zeros(1000)]), dtype=np.int16)
pip_2 = np.array(np.concatenate([np.zeros(1000), np.ones(5)*-32000, np.ones(5)*32000, np.ones(5)*-32000, np.zeros(1000)]), dtype=np.int16)

fs_1 = 88200
fs_2 = 44100
count = 0

def limit(x): # limits x to be between 0 and 1
    return max(min(x,1),0)

while True:
        dist = drv.getDistance()
        print(dist)

        activate += limit((1 - min(dist, 5000)/5000)*np.random.rand())
        deactivate += limit((count/10*np.random.rand() - activate)/20)

        right_spikes = nrn_1.update(activate, pip=pip_1, fs=fs_1)
        left_spikes = nrn_2.update(deactivate, pip=pip_2, fs=fs_2)

        print("Left Spikes: ", left_spikes, "Right Spikes: ", right_spikes)
        ## Comment to remove plotting
        line1.set_ydata(nrn_1.history(10000))
        line2.set_ydata(nrn_2.history(10000))
        ax.draw_artist(line1)
        ax.draw_artist(line2)
        plt.pause(0.001)
        ## /Comment to remove plotting

        
        if right_spikes > left_spikes:
            drv.right(1)
            activate = 0
            count = 0
        elif left_spikes > right_spikes:
            drv.left(1)
            count -= 10
            deactivate = 0
        else:
            drv.forward(1)

        count += 1
        if keyboard.is_pressed('q'):
            time.sleep(0.2)
            drv.stop()
            time.sleep(0.2)
            drv.close()
            break
