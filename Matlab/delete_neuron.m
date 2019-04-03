
% Remove select neuron menu
delete(text_heading)
delete(button1)
delete(button2)
delete(button3)
delete(button4)
delete(button_cancel)

% Remove variables
nneurons = nneurons - 1;
neuron_xys(presynaptic_neuron, :) = [];
connectome(presynaptic_neuron, :) = [];
connectome(:, presynaptic_neuron) = [];
da_connectome(presynaptic_neuron, :, :) = [];
da_connectome(:, presynaptic_neuron, :) = [];
a(presynaptic_neuron) = [];
b(presynaptic_neuron) = [];
c(presynaptic_neuron) = [];
d(presynaptic_neuron) = [];
v(presynaptic_neuron) = [];
u(presynaptic_neuron) = [];
spikes_loop(presynaptic_neuron, :) = [];
neuron_contacts(presynaptic_neuron, :) = [];
vis_prefs(presynaptic_neuron, :, :) = [];
dist_prefs(presynaptic_neuron, :) = [];
neuron_cols(presynaptic_neuron, :) = [];
network_ids(presynaptic_neuron, :) = [];
steps_since_last_spike(presynaptic_neuron) = [];
da_rew_neurons(presynaptic_neuron, :) = [];
bg_neurons(presynaptic_neuron, :) = [];

% Clear neurons
clear presynaptic_neuron

% Draw brain
draw_brain


