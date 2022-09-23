
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
neuron_scripts(presynaptic_neuron, :) = [];

if supervocal && isfield(brain, 'audio_out_wavs')
    this_tone = neuron_tones(presynaptic_neuron, :);
    if this_tone  > (n_out_sounds + n_vis_prefs) && this_tone <= size(audio_out_wavs, 2)
        these_tones = neuron_tones > this_tone & neuron_tones <= size(audio_out_wavs, 2);
        neuron_tones(these_tones, 1) = neuron_tones(these_tones, 1) - 1;        
        audio_out_wavs(this_tone) = [];
        audio_out_fs(this_tone) = [];
        audio_out_names(this_tone) = [];
        audio_out_durations(this_tone) = [];
    end
end

neuron_tones(presynaptic_neuron, :) = [];
if exist('audio_out_wavs', 'var')
    brain.audio_out_wavs = audio_out_wavs; % This should be done with the others
end
if exist('audio_out_names', 'var')
    brain.audio_out_names = audio_out_names; % This should be done with the others
end

% Clear neurons
clear presynaptic_neuron

% Draw brain
draw_brain

% Restore design buttons
design_buttons

