






clc
clear
brain_dir = strcat(userpath, '\Brains\')
load(strcat(brain_dir, 'vertebot_brain.mat'))

%%
brain_dir = strcat(userpath, '\Brains\')
available_brains = dir(strcat(brain_dir, '*.mat'))
nbrains = size(available_brains, 1)


%% Settings
pulse_period = 0.1;         % Step time in seconds
night_vision = 0;           % Use histeq to enhance image contrast
use_speech2text = 0;        % In progress, requires key
save_data_and_commands = 0;
bg_brain = 1;
script_names = {'Red LEDs on', 'Green LEDs on', 'Blue LEDs on', 'Delayer', 'Counter'};
init_motor_block_in_s = 1;
gui_font_name = 'Comic Book';
gui_font_weight = 'normal';
bfsize = 10;


%% Background
grey_background = 1; % Grey background (1) or white background (0)    
if grey_background
    fig_bg_col = [0.94 0.94 0.94];
    this_workspace_fig = 'workspace3.jpg';
else
    fig_bg_col = [1 1 1];
    this_workspace_fig = 'workspace4.jpg';
end
im = flipud(255 - ((255 - imread(this_workspace_fig))));
im2 = flipud(255 - ((255 - imread(this_workspace_fig))));


%% Prep variables necessary for brain load
ms_per_step = round(pulse_period * 1000);
nsteps_per_loop = 100;
contact_xys = [-1.2, 2.05; 1.2, 2.1; -2.08, -0.38; 2.14, -0.38; ...
    -0.05, 2.45; -1.9, 1.45; -1.9, 0.95; -1.9, -1.78; ...
    -1.9, -2.28; 1.92, 1.49; 1.92, 0.95; 1.92, -1.82; 1.92, -2.29];
ncontacts = size(contact_xys, 1);
trained_nets = cell(1);


%% Miscellaneous
robot_xy = [234 53];
prev_robot_xy = [66 343];
network_colors = [1 0.9 0.8; 0.4940 0.1840 0.5560; ...
    0.9 0.4250 0.0980; 1 0 1; 1 1 0; 1 0 1; ...
    0.4660 0.6740 0.1880; 0 1 1; 0.6350 0.0780 0.1840; ...
    0, 0.75, 0.75; 0, 0, 0.5];
basic_vis_pref_names = {'Red', 'Red (side)', 'Green', 'Green (side)', 'Blue', 'Blue (side)', 'Movement'};
n_basic_vis_features = size(basic_vis_pref_names, 2);


%%
vis_pref_names = basic_vis_pref_names;
microcircuit = 0;
audio_out_names = [];
bg_colors = 1;
draw_neuron_numbers = 1;
draw_synapse_strengths = 1;
for nscript = 1:size(script_names, 2)
    script_strs(nscript).name = script_names{nscript};
end
use_cnn = 1;
use_cnn_code

%%
for nbrain = 62:nbrains
    revive
    print_brain
end
