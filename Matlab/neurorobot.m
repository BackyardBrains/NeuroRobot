

% NEUROROBOT APP by Backyard Brains
% Managed by Christopher Harris, christopher@backyardbrains.com
% This code is licensed under a GNU 2.1 license
% For the best experience, install the Comic Book font (included)
% For more information, see https://www.biorxiv.org/content/10.1101/597609v1


%% Settings
brain_gen = 1;
rak_only = 0;
camera_present = 1; % Set this to 1 to use any camera for vision
use_webcam = 1; % Set this to 1 if you're using your computer's webcamera rather than the RAK module
bluetooth_present = 0;
bg_brain = 1;
draw_synapse_strengths = 0;
draw_neuron_numbers = 1;
save_brain_jpg = 0;
save_data_and_commands = 0;

bluetooth_name = 'RNBT-0C56'; % Change this to match your bluetooth name
startup_fig_pos = [1 41 1920 1017]; % Change this if your screen size is different 
fig_pos = [1 41 1920 1017]; % Change this if your screen size is different
bfsize = 18; % You may want to change this to 16 if your screen size is smaller than 1080p

second_screen_analysis = 0;
ext_cam_id = 0;
ext_cam_nsteps = 100; % check this
manual_controls = 0;
use_profile = 1;
nsteps_per_loop = 100;
brain_facts = 0;
use_cnn = 0;
pulse_period = 0.1; % in seconds
max_w = 100;
large_brain = 0;
ltp_recency_th_in_sec = 2000; % must be >= pulse_period
permanent_memory_th = 24;
fig_bg_col = [0.94 0.94 0.94];
% fig_bg_col = [1 1 1];


%% Clear
if exist('voluntary_restart', 'var') && ~voluntary_restart && ~rak_only
    delete(imaqfind)
    delete(timerfind)
    brain_view_tiled = 0;
end
clear step_timer
clear life_timer
disp('---------')
HebiCam.loadLibs();
if ~exist('voluntary_restart', 'var')
    brain_view_tiled = 0;
end


%% Constants
base_weight = max_w;
left_cut = [1 500 281 780];
right_cut = [1 500 501 1000];
left_yx = [length(left_cut(1):left_cut(2)) length(left_cut(3):left_cut(4))];
right_yx = [length(right_cut(1):right_cut(2)) length(right_cut(3):right_cut(4))];
gui_font_name = 'Comic Book';
gui_font_weight = 'normal';
load gong.mat
gong = y;
ms_per_step = round(pulse_period * 1000);
ltp_recency_th_in_steps = round(ltp_recency_th_in_sec / ms_per_step);
speaker_selected = 0;
if ~exist('voluntary_restart', 'var')
    voluntary_restart = 0;
end


%% Custom settings for Backyard Brains' classroom events
computer_name = getComputerName;
if strcmp(computer_name, 'laptop-main')
    startup_fig_pos = [1 41 1920 1017];   
    fig_pos = [1 41 1920 1017];
%     startup_fig_pos = [1921 1 1920 1057];   
%     fig_pos = [1921 1 1920 1057];    
%     bluetooth_name = 'RNBT-855E'; % red, wifi = LTH_CFFCFD
%     bluetooth_name = 'RNBT-09FE'; % green, wifi = LTH_CFD698
%     bluetooth_name = 'RNBT-9AA5'; % black, wifi = LTH_D07086
    bluetooth_name = 'RNBT-A9BE'; % blue, wifi = LTH_CFFAC8
    bfsize = 18;
elseif strcmp(computer_name, 'laptop-green')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];  
    bluetooth_name = 'RNBT-09FE'; % green, wifi = LTH_CFD698
    bfsize = 16;    
elseif strcmp(computer_name, 'laptop-red')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];  
    bluetooth_name = 'RNBT-855E'; % red, wifi = LTH_CFFCFD
    bfsize = 16;   
elseif strcmp(computer_name, 'laptop-pink')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];  
    bluetooth_name = 'RNBT-9930'; % pink, wifi = LTH_CFFAB3
    bfsize = 16;
elseif strcmp(computer_name, 'laptop-yellow')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];
    bluetooth_name = 'RNBT-0C56'; % yellow, wifi = LTH_CFFABA
    bfsize = 16;  
elseif strcmp(computer_name, 'laptop-white')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];
    bluetooth_name = 'RNBT-1FE5'; % white, wifi = LTH_CFD6F5
    bfsize = 16;
elseif strcmp(computer_name, 'laptop-blue')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];
    bluetooth_name = 'RNBT-A9BE'; % blue, wifi = LTH_CFFAC8
    bfsize = 16;
elseif strcmp(computer_name, 'laptop-orange')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];
    bluetooth_name = 'RNBT-ACFF'; % , wifi = LTH_CFFB27
    bfsize = 16;
elseif strcmp(computer_name, 'laptop-black')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];
    bluetooth_name = 'RNBT-9AA5'; % black, wifi = LTH_D07086
    bfsize = 16;
elseif strcmp(computer_name, 'laptop-purple')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];
    bluetooth_name = 'RNBT-96F3'; % purple, wifi = LTH_D070D6
    bfsize = 16;
elseif strcmp(computer_name, 'laptop-checkers')
    startup_fig_pos = [1 41 1536 800.8000];   
    fig_pos = [1 41 1536 800.8000];
    bluetooth_name = 'RNBT-855E'; % red, wifi = LTH_CFFCFD
    bfsize = 16;    
end
disp(horzcat('Computer name: ', computer_name))


%% Prepare
if isequal(fig_bg_col, [1 1 1])
    this_workspace_fig = 'workspace.jpg';
else
    this_workspace_fig = 'workspace2.jpg';
end
im = flipud(255 - ((255 - imread(this_workspace_fig))));
im2 = flipud(255 - ((255 - imread(this_workspace_fig))));
contact_xys = [-1.2, 2.05; 1.2, 2.1; -2.08, -0.38; 2.14, -0.38; ...
    -0.05, 2.45; -1.9, 1.45; -1.9, 0.95; -1.9, -1.78; ...
    -1.9, -2.28; 1.92, 1.49; 1.92, 0.95; 1.92, -1.82; 1.92, -2.29];
ncontacts = size(contact_xys, 1);
dist_pref_names = {'Short', 'Medium', 'Long'};
n_dist_prefs = size(dist_pref_names, 2);
vis_pref_names = {'red', 'green', 'blue', 'off-center red', 'off-center green', 'off-center blue'};
if use_cnn
    load object_strs
    load object_ns
    vis_pref_names = [vis_pref_names, object_strs];
end
n_vis_prefs = size(vis_pref_names, 2);
sens_thresholds = [10 10 10 10 10 10 10 10 10 10 10 10 10 10 10];
encoding_pattern = ones(size(sens_thresholds));
if ~exist('restarting', 'var')
    restarting = 0;
end
if ~exist('restarts', 'var')
    restarts = 0;
end


%% Prepare figure
fig_startup = figure(1);
clf
set(fig_startup, 'NumberTitle', 'off', 'Name', 'Neurorobot Startup')
set(fig_startup, 'menubar', 'none', 'toolbar', 'none')
set(fig_startup, 'position', startup_fig_pos, 'color', fig_bg_col) 

% Title
text_title = uicontrol('Style', 'text', 'String', 'Neurorobot Startup', 'units', 'normalized', 'position', [0.05 0.9 0.9 0.05], ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 10, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

% Select brain
text_load = uicontrol('Style', 'text', 'String', 'Select brain', 'units', 'normalized', 'position', [0.05 0.8 0.35 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 8, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
clear brain_string
brain_string{1} = '-- Create new brain --';
brain_directory = '.\Brains\*.mat';
available_brains = dir(brain_directory);
nbrains = size(available_brains, 1);
for nbrain = 1:nbrains
    brain_string{nbrain + 1} = available_brains(nbrain).name(1:end-4);
end
popup_select_brain = uicontrol('Style', 'popup', 'String', brain_string, 'callback', 'update_brain_name_edit', 'units', 'normalized', ...
    'position', [0.05 0.7 0.35 0.1], 'fontsize', bfsize + 8, 'fontweight', gui_font_weight, 'FontName', gui_font_name);
if ~restarting
    brain_name = '';
end
text_name = uicontrol('Style', 'text', 'String', 'Brain name', 'units', 'normalized', 'position', [0.05 0.65 0.35 0.05], ....
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 8, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
edit_name = uicontrol('Style', 'edit', 'String', brain_name, 'units', 'normalized', 'position', [0.05 0.55 0.35 0.1], 'fontsize', bfsize + 8, ....
    'FontName', gui_font_name, 'fontweight', gui_font_weight);

% Camera button
if exist('rak_fail', 'var') && ~rak_fail && exist('rak_pulse', 'var') && isvalid(rak_pulse) && strcmp(rak_pulse.Running, 'on')
    this_col = [0.6 0.95 0.6];
elseif (exist('rak_fail', 'var') && rak_fail) || (exist('rak_pulse', 'var') && isvalid(rak_pulse) && strcmp(rak_pulse.Running, 'off'))
    this_col = [1 0.5 0.5];
else
    this_col = [0.8 0.8 0.8];
end
button_camera = uicontrol('Style', 'pushbutton', 'String', 'Connect camera(s)', 'units', 'normalized', 'position', [0.05 0.4 0.35 0.1]);
set(button_camera, 'Callback', '[rak_cam, rak_pulse] = connect_rak(button_camera, pulse_period, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only); ext_cam = connect_ext_cam(button_camera, ext_cam_id); start(rak_pulse)', ...
    'FontSize', bfsize + 8, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', this_col)
if ~camera_present
    set(button_camera, 'BackgroundColor', [0.8 0.8 0.8], 'enable', 'off')
end

% Bluetooth button
distance_read = 0;
if ~rak_only
    if exist('bluetooth_modem', 'var')
        while bluetooth_modem.BytesAvailable
            distance_read = fgetl(bluetooth_modem);
        end
        distance_read = str2double(distance_read);    
    end
    if exist('bluetooth_modem', 'var') && ~isnan(distance_read)
        this_col = [0.6 0.95 0.6];
    elseif exist('bluetooth_modem', 'var') && isnan(distance_read)
        this_col = [1 0.5 0.5];
    else
        this_col = [0.8 0.8 0.8];
    end
    button_bluetooth = uicontrol('Style', 'pushbutton', 'String', 'Connect bluetooth', 'units', 'normalized', 'position', [0.05 0.25 0.35 0.1]);
    set(button_bluetooth, 'Callback', 'bluetooth_modem = connect_bluetooth(bluetooth_name, button_bluetooth, text_title, text_load, popup_select_brain, edit_name, button_camera, button_startup_complete, camera_present, bluetooth_present); ', 'FontSize', bfsize + 8, 'FontName', gui_font_name, ...
        'FontWeight', gui_font_weight, 'BackgroundColor', this_col)
    if ~bluetooth_present
        set(button_bluetooth, 'BackgroundColor', [0.8 0.8 0.8], 'enable', 'off')
    end
else
    button_bluetooth = uicontrol('Style', 'pushbutton', 'String', 'Connect bluetooth', 'units', 'normalized', 'position', [0.05 0.25 0.35 0.1]);
    set(button_bluetooth, 'Callback', 'bluetooth_modem = connect_bluetooth(bluetooth_name, button_bluetooth, text_title, text_load, popup_select_brain, edit_name, button_camera, button_startup_complete, camera_present, bluetooth_present); ', 'FontSize', bfsize + 8, 'FontName', gui_font_name, ...
        'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
    set(button_bluetooth, 'enable', 'off')
end

% % Optional object detection
% text_ood = uicontrol('Style', 'text', 'String', 'Object detection', 'units', 'normalized', 'position', [0.13 0.25 0.17 0.06], 'backgroundcolor', 'w', 'fontsize', bfsize + 8, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
% check_ood = uicontrol('Style', 'checkbox', 'units', 'normalized', 'position', [0.3 0.25 0.09 0.05], 'BackgroundColor', 'w');

% Start button
button_startup_complete = uicontrol('Style', 'pushbutton', 'String', 'Start neurorobot', 'units', 'normalized', 'position', [0.05 0.1 0.35 0.1]);
set(button_startup_complete, 'Callback', 'startup_complete', 'FontSize', bfsize + 8, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])

% Brain display
brain_ax = axes('position', [0.475 0.1 0.45 0.75]);
image('CData',im2,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)
axis([-3 3 -3 3])
hold on
box off
ext_ax = brain_ax;


% Restart code
if exist('restarting', 'var') && restarting
    
    % Lock GUI
    disp('Restarting...')
    text_title.String = 'Restarting...';
    set(button_bluetooth, 'enable', 'off')
    set(popup_select_brain, 'visible', 'off')
    set(edit_name, 'enable', 'off')
    set(button_camera, 'enable', 'off')
    set(button_startup_complete, 'enable', 'off')
    drawnow
    
    % Attempt to reconnect RAK
    if ~voluntary_restart && camera_present
        [rak_cam, rak_pulse] = connect_rak(button_camera, pulse_period, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only);
        start(rak_pulse)
        disp('RAK reconnected')
    end
    voluntary_restart = 0;
    
    % Update brain selection properties
    for nbrain = 1:nbrains
        if strcmp(brain_name, available_brains(nbrain).name(1:end-4))
            nbrains = size(available_brains, 1);
            popup_select_brain.Value = nbrain + 1;
        end
    end    
    edit_name.String = brain_name;
    
    % Restore GUI
    restarting = 0;
    if bluetooth_present
        set(button_bluetooth, 'enable', 'on')
    end
    set(popup_select_brain, 'visible', 'on')
    set(edit_name, 'enable', 'on')
    if camera_present
        set(button_camera, 'enable', 'on')
    end
    set(button_startup_complete, 'enable', 'on')
    text_title.String = 'Neurorobot Startup';
    drawnow
    
    startup_complete
end
    