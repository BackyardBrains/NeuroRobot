
% Command log
if save_data_and_commands
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    command_log.entry(command_log.n).time = this_time;    
    command_log.entry(command_log.n).action = 'delete neuron';
    command_log.n = command_log.n + 1;
end

% Remove select neuron menu
delete(text_heading)
delete(button1)
delete(button2)
delete(button3)
delete(button4)
delete(button5)
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
audio_prefs(presynaptic_neuron, :) = [];
neuron_cols(presynaptic_neuron, :) = [];
network_ids(presynaptic_neuron, :) = [];
steps_since_last_spike(presynaptic_neuron) = [];
da_rew_neurons(presynaptic_neuron, :) = [];
bg_neurons(presynaptic_neuron, :) = [];

% Clear neurons
clear presynaptic_neuron

if ~exist('presynaptic_neuron', 'var')
    set(button_add_neuron, 'enable', 'on')
    set(button_add_network, 'enable', 'on')
    set(button_return_to_runtime, 'enable', 'on')
end

% Draw brain
draw_brain


