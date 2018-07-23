
import PyQt5
from utils.driver import Driver

from brian2 import *
import numpy as np
import matplotlib.pyplot as plt
import time
import keyboard

fig, ax = plt.subplots()
ax.set_ylim([0,1])
line1, = ax.plot(np.linspace(0,10000,10000), np.zeros(10000), 'r-')
plt.show(block=False)
fig.canvas.draw()

drv = Driver()
drv.raiseSpeed()
time.sleep(0.1)
drv.raiseSpeed()
time.sleep(0.1)
drv.raiseSpeed()
time.sleep(0.1)


start_scope()
G = NeuronGroup(1, '''dv/dt = (-v + active)/(10*ms) : 1
                       active : 1  # will be set in the network operation''',
               threshold='v>0.8', reset='v = 0', refractory=5*ms)
M = StateMonitor(G, 'v', record=True)
S = SpikeMonitor(G)

count = 0
prev_spikes = 0

@network_operation(dt=10*ms)
def update_active():
    global count, fig, ax, line1, prev_spikes, drv, S
    if count > 100: # update plotting
        dist = drv.getDistance(delay=0.1)
        G.active_ = np.round(max(1 - min(dist, 5000)/10000, 0))

        line1.set_ydata(M.v[0][100*(count-101):100*(count-101)+10000])
        ax.draw_artist(line1)
        # fig.canvas.update()       
        fig.canvas.flush_events()
        plt.pause(0.01)

        if prev_spikes<S.num_spikes:
            drv.right(1)
        else:
            drv.forward(1)

        prev_spikes = S.num_spikes

        # Exit condition
        if keyboard.is_pressed('q'):
            time.sleep(0.1)
            drv.stop()
            plt.close()
            drv.close()
            return

    count += 1

    
run(100000000*ms)
drv.close()
plt.close()
