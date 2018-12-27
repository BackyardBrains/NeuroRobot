import time
import sounddevice as sd
import matplotlib.pyplot as plt
import numpy as np
from brian2 import (Network, NetworkOperation, NeuronGroup, SpikeMonitor,
                    StateMonitor, ms)


class Neuron(object):
    def __init__(self, group=None): 
        if group is None:
            # default to Izhikevich model neuron
            eq = '''dv/dt = (0.04*active/ms/mV + 0.04/ms/mV)*v**2+(5/ms)*v+140*mV/ms-w + I : volt (unless refractory)
                    dw/dt = (0.02/ms)*((0.2/ms)*v-w) : volt/second
                    active : 1
                    I : volt/second'''
            # create 1 neuron with 1 output
            self.group = Neuron(NeuronGroup(1, eq, threshold='v > 50*mV', reset='v = -50*mV', refractory=10*ms, method='rk2'))
        else:
            self.group = group

        self.state_monitor = StateMonitor(self.group, 'v', record=True) # monitor voltages
        self.spike_monitor = SpikeMonitor(self.group)
        self.operator = NetworkOperation(self.update_active, dt=100*ms)

        # initialise network object for neuron to run in and add elements
        self.network = Network()
        self.network.add(self.group)
        self.network.add(self.state_monitor)
        self.network.add(self.spike_monitor)
        self.network.add(self.operator)

        self.input = 0

    # function for updating neuron state
    def update_active(self):
        self.group.active = self.input

    def update(self, input=0, dt=100, pip=None, fs=44100): #run simulation for dt milliseconds, return number of spikes which occur
        self.input = input
        prev = self.spike_monitor.num_spikes
        self.network.run(dt*ms)
        spikes = self.spike_monitor.num_spikes - prev

        if pip is not None and spikes > 0: # if there is a sound to play, play it
            sd.play(np.tile(pip, spikes+1))
        return spikes

    def history(self, length): # returns last 'length' samples of state monitor
        state_len = len(self.state_monitor.v[0])
        v_history = self.state_monitor.v[0][max(state_len - length, 0):state_len]
        if state_len - length < 0:
            pad = np.zeros(length - state_len)
            v_history = np.concatenate([pad, v_history])

        return v_history
        
