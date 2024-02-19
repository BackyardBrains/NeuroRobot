


%% The SpikerBot App
% Christopher Harris
% christopher@backyardbrains.com
% Backyard Brains, Inc.



%% Settings
pulse_period = 0.1;         % Step time in seconds
night_vision = 0;           % Use histeq to enhance image contrast
use_speech2text = 0;        % In progress, requires key
save_data_and_commands = 0;
bg_brain = 1;
script_names = {'Red LEDs on', 'Green LEDs on', 'Blue LEDs on', 'not in use', 'Trained Network'};
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


%% Directory setup
dir_setup


%% Screensize
if ismac
    startup_fig_pos = get(0, 'screensize') + [0 149 0 -171];
    fig_pos = get(0, 'screensize') + [0 149 0 -171];
else
    startup_fig_pos = get(0, 'screensize') + [0 49 0 -71];
    fig_pos = get(0, 'screensize') + [0 49 0 -71];
end


%% Prepare figure
fig_startup = figure(1);
clf
set(fig_startup, 'NumberTitle', 'off', 'Name', 'SpikerBot 4.6')
set(fig_startup, 'menubar', 'none', 'toolbar', 'none')
set(fig_startup, 'position', startup_fig_pos, 'color', fig_bg_col)

% Title
text_title = uicontrol('Style', 'text', 'String', 'SpikerBot 4.6', 'units', 'normalized', 'position', [0.05 0.7 0.9 0.25], ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 40, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);


%% Miscellaneous
robot_xy = [234 53];
prev_robot_xy = [66 343];
network_colors = [1 0.9 0.8; 0.4940 0.1840 0.5560; ...
    0.9 0.4250 0.0980; 1 0 1; 1 1 0; 1 0 1; ...
    0.4660 0.6740 0.1880; 0 1 1; 0.6350 0.0780 0.1840; ...
    0, 0.75, 0.75; 0, 0, 0.5];
    basic_vis_pref_names = {'Red', 'Red (side)', 'Green', 'Green (side)', 'Blue', 'Blue (side)', 'Movement'};
    n_basic_vis_features = size(basic_vis_pref_names, 2);
    

%% Selection
% Robot
option_robot = {...
    'SpikerBot RAK5206'; ...
    'SpikerBot RAK5270'; ...
    'SpikerBot ESP32'; ...
    'Computer with webcam'; ...
    'Computer without webcam'; ...
    'ESP32 with webcam'
    };

text_robot = uicontrol('Style', 'text', 'String', 'Robot', 'units', 'normalized', 'position', [0.05 0.735 0.25 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
select_robot = uicontrol('Style', 'list', 'Callback', 'camera_button_col', 'units', 'normalized', 'Position', [0.05 0.45 0.25 0.3], ...
    'fontsize', bfsize + 4, 'string', option_robot, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 1, 'min', 1);
select_robot.Value = 3;

% App Settings
text_app = uicontrol('Style', 'text', 'String', 'App', 'units', 'normalized', 'position', [0.05 0.335 0.25 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
option_app = {'Record Data'};
select_app = uicontrol('Style', 'list', 'units', 'normalized', 'Position',[0.05 0.15 0.25 0.2], ...
    'fontsize', bfsize + 4, 'string', option_app, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 10, 'min', 0);
select_app.Value = [];

% Nets
option_nets = {'GoogLeNet', 'Custom R-CNN'}; % Imported nets
nimported = length(option_nets);
available_nets = dir(strcat(nets_dir_name, '*-ml.mat'));
nnets = length(available_nets); % Trained nets
for nnet = 1:nnets
    option_nets{nimported + nnet} = available_nets(nnet).name(1:end-7);
end
text_nets = uicontrol('Style', 'text', 'String', 'Trained Networks', 'units', 'normalized', 'position', [0.35 0.735 0.25 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
select_nets = uicontrol('Style', 'list', 'units', 'normalized', 'Position',[0.35 0.45 0.25 0.3], ...
    'fontsize', bfsize + 4, 'string', option_nets, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 2, 'min', 0);
select_nets.Value = [];

% Communication
text_communication = uicontrol('Style', 'text', 'String', 'Communication', 'units', 'normalized', 'position', [0.35 0.335 0.25 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
option_communication = {'Microphone'; 'Custom sounds'; 'Speech'; 'Multi-tone'};
select_communication = uicontrol('Style', 'list', 'units', 'normalized', 'Position',[0.35 0.15 0.25 0.2], ...
    'fontsize', bfsize + 4, 'string', option_communication, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 10, 'min', 0);
text_communication.Value = 1;

% Brains
clear brain_string
nbrains = size(available_brains, 1);
for nbrain = 1:nbrains
    brain_string{nbrain} = available_brains(nbrain).name(1:end-4);
end

text_brain = uicontrol('Style', 'text', 'String', 'Brain', 'units', 'normalized', 'position', [0.675 0.735 0.25 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
select_brain = uicontrol('Style', 'list', 'units', 'normalized', 'Position',[0.675 0.375 0.25 0.375], ...
    'fontsize', bfsize + 4, 'string', brain_string, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 1, 'min', 1);

text_new_name = uicontrol('Style', 'text', 'String', 'Name', 'units', 'normalized', 'position', [0.675 0.255 0.25 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
brain_edit_name = uicontrol('Style', 'edit', 'String', '', 'units', 'normalized', 'position', [0.675 0.22 0.25 0.05], 'fontsize', bfsize + 6, ....
    'FontName', gui_font_name, 'fontweight', gui_font_weight);
button_new_brain = uicontrol('Style', 'pushbutton', 'String', 'Create New Brain', 'units', 'normalized', 'position', [0.675 0.15 0.15 0.05]);
set(button_new_brain, 'Callback', 'initialize_brain; save_brain; neurorobot', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])


%% Buttons
button1_pos = [0.03 0.02 0.17 0.05];
button2_pos = [0.22 0.02 0.17 0.05];
button3_pos = [0.41 0.02 0.17 0.05];
button4_pos = [0.6 0.02 0.17 0.05];
button5_pos = [0.79 0.02 0.17 0.05];

% Camera button
button_camera = uicontrol('Style', 'pushbutton', 'String', 'Connect', 'units', 'normalized', 'position', button1_pos);
set(button_camera, 'Callback', 'camera_button_callback; camera_button_col', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
camera_button_col

% Start button
button_startup_complete = uicontrol('Style', 'pushbutton', 'String', 'Runtime', 'units', 'normalized', 'position', button2_pos);
set(button_startup_complete, 'Callback', 'runtime_prep', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])

% Simulator button
button_to_simulator = uicontrol('Style', 'pushbutton', 'String', 'Simulator', 'units', 'normalized', 'position', button3_pos);
set(button_to_simulator, 'Callback', 'callback_2ns', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])
% set(button_to_simulator, 'Enable', 'off')

% ML button
button_to_sleep = uicontrol('Style', 'pushbutton', 'String', 'Learning', 'units', 'normalized', 'position', button4_pos);
set(button_to_sleep, 'Callback', 'ml_code', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])

% Quit button
button_to_quit = uicontrol('Style', 'pushbutton', 'String', 'Quit', 'units', 'normalized', 'position', button5_pos);
set(button_to_quit, 'Callback', 'closereq', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])

