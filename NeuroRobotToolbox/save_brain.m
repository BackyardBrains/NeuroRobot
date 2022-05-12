
% Log command
if save_data_and_commands
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    command_log.entry(command_log.n).time = this_time;            
    command_log.entry(command_log.n).action = 'save brain';
    command_log.n = command_log.n + 1;
end

% Collect variables
brain.nneurons = nneurons;
brain.neuron_xys = neuron_xys;
brain.connectome = connectome;
brain.da_connectome = da_connectome;
brain.a_init = a_init;
brain.b_init = b_init;
brain.c_init = c_init;
brain.d_init = d_init;
brain.w_init = w_init;
brain.a = a;
brain.b = b;
brain.c = c;
brain.d = d;
brain.v = v;
brain.u = u;
brain.neuron_contacts = neuron_contacts;
brain.vis_prefs = vis_prefs;
brain.audio_prefs = audio_prefs;
brain.dist_prefs = dist_prefs;
brain.neuron_cols = neuron_cols;
brain.network_ids = network_ids;
brain.da_rew_neurons = da_rew_neurons;
brain.neuron_tones = neuron_tones;
brain.neuron_scripts = neuron_scripts;
brain.network_drive = network_drive;
% brain.network = network;
brain.bg_neurons = bg_neurons;

% Save brain
brain_file_name = strcat('.\Brains\', brain_name, '.mat');
save(brain_file_name, 'brain')
if exist('button_save', 'var') && isvalid(button_save) && ~restarting
    for ii = 1:-0.05:0.8
        button_save.BackgroundColor = [0.8 ii 0.8];
        pause(0.05)
    end
end

run_button = 0;
design_button = 0;
disp('Brain saved')
