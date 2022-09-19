




%% The SpikerBot App
% Christopher Harris, PhD
% Backyard Brains, Inc
% christopher@backyardbrains.com






%% Settings 
pulse_period = 0.2;         % Step time in seconds
dev_mode = 0;               % Run brainless_first_visual_line once & brainless persistantly in rak_pulse_code
night_vision = 0;           % Use histeq to enhance image contrast
brain_gen = 0;              % Use "Create New Brain" to algorithmically generate new brains
cpg_integration = 1;        % Add New Neurons (0 = semi random, 1 = add previously designed brains as CPGs)
use_speech2text = 0;        % In progress, requires key
save_brain_jpg = 0;         % Needs export_fig
save_data_and_commands = 0;
% use_profile = 0;          % Disabled for packaging
bg_brain = 1;
manual_controls = 0;
script_names = {'Red LEDs on', 'Green LEDs on', 'Blue LEDs on', 'LEDs off', 'Agent Heliomax', 'Deep Agent Heliomax'};
data_dir_name = '.\Data\';
rec_dir_name = '';
init_motor_block_in_s = 2;
gui_font_name = 'Comic Book';
gui_font_weight = 'normal';
bfsize = 9;
ms_per_step = round(pulse_period * 1000);
nsteps_per_loop = 100;


%% Background
% Grey background (1) or white background (0)
grey_background = 1;        
if grey_background
    fig_bg_col = [0.94 0.94 0.94];
    this_workspace_fig = 'workspace2.jpg';
else
    fig_bg_col = [1 1 1];
    this_workspace_fig = 'workspace.jpg';
end
im = flipud(255 - ((255 - imread(this_workspace_fig))));
im2 = flipud(255 - ((255 - imread(this_workspace_fig))));

%% Screensize
if ismac
    startup_fig_pos = get(0, 'screensize') + [0 149 0 -171];
    fig_pos = get(0, 'screensize') + [0 149 0 -171];
else
    startup_fig_pos = get(0, 'screensize') + [0 49 0 -71];
%     startup_fig_pos(1) = startup_fig_pos(1) + 50;
%     startup_fig_pos(2) = startup_fig_pos(2) + 50;
%     startup_fig_pos(3) = startup_fig_pos(3) - 100;
%     startup_fig_pos(4) = startup_fig_pos(4) - 150;

    fig_pos = get(0, 'screensize') + [0 49 0 -71];
%     fig_pos(1) = fig_pos(1) + 50;
%     fig_pos(2) = fig_pos(2) + 50;
%     fig_pos(3) = fig_pos(3) - 100;
%     fig_pos(4) = fig_pos(4) - 150;    
end

%% Prepare figure
fig_startup = figure(1);
clf
set(fig_startup, 'NumberTitle', 'off', 'Name', 'SpikerBot - Main Menu')
set(fig_startup, 'menubar', 'none', 'toolbar', 'none')
set(fig_startup, 'position', startup_fig_pos, 'color', fig_bg_col) 

% Title
text_title = uicontrol('Style', 'text', 'String', 'SpikerBot - Main Menu', 'units', 'normalized', 'position', [0.05 0.7 0.9 0.25], ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 40, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

%% Selection
% Robot
text_robot = uicontrol('Style', 'text', 'String', 'Robot', 'units', 'normalized', 'position', [0.05 0.735 0.2 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
option_robot = {'SpikerBot RAK5206'; 'SpikerBot RAK5270'; 'SpikerBot ESP32';'Computer with Camera'};
select_robot = uicontrol('Style', 'list', 'Callback', 'camera_button_col', 'units', 'normalized', 'Position', [0.05 0.55 0.2 0.2], ...
    'fontsize', bfsize + 4, 'string', option_robot, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 1, 'min', 1);

% App Settings
text_app = uicontrol('Style', 'text', 'String', 'App Settings', 'units', 'normalized', 'position', [0.05 0.435 0.2 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
option_app = {'Basal Ganglia Colors', 'Draw Neuron Numbers'; 'Draw Synapse Weights', 'Record Data'};
select_app = uicontrol('Style', 'list', 'units', 'normalized', 'Position',[0.05 0.15 0.2 0.3], ...
    'fontsize', bfsize + 4, 'string', option_app, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 10, 'min', 0);

% Vision
text_vision = uicontrol('Style', 'text', 'String', 'Vision', 'units', 'normalized', 'position', [0.325 0.735 0.2 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
option_vision = {'RandomWalk'; 'AlexNet'; 'Robots'; 'Faces'};
select_vision = uicontrol('Style', 'list', 'units', 'normalized', 'Position',[0.325 0.55 0.2 0.2], ...
    'fontsize', bfsize + 4, 'string', option_vision, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 10, 'min', 0);

% Communication
text_communication = uicontrol('Style', 'text', 'String', 'Communication', 'units', 'normalized', 'position', [0.325 0.435 0.2 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
option_communication = {'Microphone/FFT'; 'Speech2Text';'Text2Speech'; 'OpenAI'};
select_communication = uicontrol('Style', 'list', 'units', 'normalized', 'Position',[0.325 0.15 0.2 0.3], ...
    'fontsize', bfsize + 4, 'string', option_communication, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 10, 'min', 0);

% Brain
clear brain_string
brain_string{1} = '-- Create new brain --';
if ispc
    available_brains = dir('.\Brains\*.mat');
elseif ismac && ~isdeployed
    available_brains = dir('./Brains/*.mat');
elseif ismac && isdeployed
    available_brains = struct;
    available_brains(1,1).name = 'Betsy.mat';
    available_brains(2,1).name = 'Chopin.mat';
    available_brains(3,1).name = 'Critter.mat';
    available_brains(4,1).name = 'Glunkakakakah.mat';
    available_brains(5,1).name = 'Merlin.mat'; 
    available_brains(6,1).name = 'Pavlov.mat';
    available_brains(7,1).name = 'SingSong.mat';
    available_brains(8,1).name = 'ZiggyZag.mat';
end

nbrains = size(available_brains, 1);
for nbrain = 1:nbrains
    brain_string{nbrain} = available_brains(nbrain).name(1:end-4);
end

text_brain = uicontrol('Style', 'text', 'String', 'Brain', 'units', 'normalized', 'position', [0.6 0.735 0.25 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
select_brain = uicontrol('Style', 'list', 'units', 'normalized', 'Position',[0.6 0.375 0.25 0.375], ...
    'fontsize', bfsize + 4, 'string', brain_string, 'fontweight', gui_font_weight, 'FontName', gui_font_name, 'max', 1, 'min', 1);

text_new_name = uicontrol('Style', 'text', 'String', 'Name', 'units', 'normalized', 'position', [0.6 0.255 0.25 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
brain_edit_name = uicontrol('Style', 'edit', 'String', '', 'units', 'normalized', 'position', [0.6 0.22 0.25 0.05], 'fontsize', bfsize + 6, ....
    'FontName', gui_font_name, 'fontweight', gui_font_weight);
button_new_brain = uicontrol('Style', 'pushbutton', 'String', 'Create New Brain', 'units', 'normalized', 'position', [0.6 0.15 0.15 0.05]);
set(button_new_brain, 'Callback', 'initialize_brain; neurorobot', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])

%% Buttons
button1_pos = [0.03 0.02 0.17 0.05];
button2_pos = [0.22 0.02 0.17 0.05];
button3_pos = [0.41 0.02 0.17 0.05];
button4_pos = [0.6 0.02 0.17 0.05];
button5_pos = [0.79 0.02 0.17 0.05];

% Camera button
button_camera = uicontrol('Style', 'pushbutton', 'String', 'Connect', 'units', 'normalized', 'position', button1_pos);
set(button_camera, 'Callback', 'camera_button_callback; camera_button_col ', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

% Start button
button_startup_complete = uicontrol('Style', 'pushbutton', 'String', 'Runtime', 'units', 'normalized', 'position', button2_pos);
set(button_startup_complete, 'Callback', 'startup_complete', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])

% Library button
button_to_library = uicontrol('Style', 'pushbutton', 'String', 'Library', 'units', 'normalized', 'position', button3_pos);
set(button_to_library, 'Callback', '', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])

% Sleep button
button_to_sleep = uicontrol('Style', 'pushbutton', 'String', 'Sleep', 'units', 'normalized', 'position', button4_pos);
set(button_to_sleep, 'Callback', '', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])

% Quit button
button_to_quit = uicontrol('Style', 'pushbutton', 'String', 'Quit', 'units', 'normalized', 'position', button5_pos);
set(button_to_quit, 'Callback', '', 'FontSize', bfsize + 6, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])




