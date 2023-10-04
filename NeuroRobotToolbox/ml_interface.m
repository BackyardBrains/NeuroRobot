

%% Lock
disp('Preparing ML interface...')
button_to_sleep.BackgroundColor = [0.94 0.78 0.62];
set(button_camera, 'enable', 'off')
set(button_startup_complete, 'enable', 'off')
set(button_to_library, 'enable', 'off')
set(button_to_sleep, 'enable', 'off')
set(button_to_quit, 'enable', 'off')
set(button_new_brain, 'enable', 'off')
drawnow


%% Prepare figure
fig_ml = figure(3);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'SpikerBot - Learning')
set(fig_ml, 'menubar', 'none', 'toolbar', 'none')
set(fig_ml, 'position', fig_pos, 'color', fig_bg_col) 


%% Positions
alearn_title_pos =              [0.03 0.92 0.44 0.05];

alearn_data_str_pos =           [0.03 0.8 0.1 0.05];
alearn_data_select_pos =        [0.16 0.8 0.31 0.05];

alearn_load_button_pos =        [0.03 0.73 0.1 0.05];
alearn_load_status_pos =        [0.16 0.73 0.31 0.05];

alearn_name_str_pos =           [0.03 0.65 0.1 0.05];
alearn_name_edit_pos =          [0.16 0.65 0.31 0.05];

alearn_speed_str_pos =          [0.03 0.58 0.1 0.05];
alearn_speed_select_pos =       [0.16 0.58 0.31 0.05];

alearn_train_button_pos =       [0.03 0.5 0.1 0.05];
alearn_train_status_pos =       [0.16 0.5 0.31 0.05];

im_ax1_pos =                    [0.16 0.15 0.31 0.3];

olearn_title_pos =              [0.53 0.92 0.44 0.05];

olearn_net_load_str_pos =       [0.53 0.73 0.1 0.05];
olearn_net_load_select_pos =    [0.66 0.73 0.31 0.05];

olearn_data_str_pos =           [0.53 0.8 0.1 0.05];
olearn_data_select_pos =        [0.66 0.8 0.31 0.05];
olearn_load_button_pos =        [0.53 0.65 0.1 0.05];
olearn_load_status_pos =        [0.66 0.65 0.31 0.05];

olearn_late_load_button_pos =   [0.53 0.5 0.1 0.05];
olearn_late_load_status_pos =   [0.66 0.5 0.31 0.05];

olearn_name_str_pos =           [0.53 0.42 0.1 0.05];
olearn_name_edit_pos =          [0.66 0.42 0.31 0.05];

olearn_goal_str_pos =           [0.53 0.34 0.1 0.05];
olearn_goal_edit_pos =          [0.66 0.34 0.31 0.05];

olearn_speed_str_pos =          [0.53 0.26 0.1 0.05];
olearn_speed_select_pos =       [0.66 0.26 0.31 0.05];

olearn_train_button_pos =       [0.53 0.18 0.1 0.05];
olearn_train_status_pos =       [0.66 0.18 0.31 0.05];

button_exit_ml_pos =            [0.35 0.03 0.3 0.05];


%% Titles
alearn_title = uicontrol('Style', 'text', 'String', 'Associative Learning', 'units', 'normalized', 'position', alearn_title_pos, ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);
olearn_title = uicontrol('Style', 'text', 'String', 'Reinforcment Learning', 'units', 'normalized', 'position', olearn_title_pos, ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);


%% Load net
available_nets = dir(strcat(nets_dir_name, '*-ml.mat'));
nnets = length(available_nets); % Trained nets
for nnet = 1:nnets
    training_nets{nnet} = available_nets(nnet).name(1:end-7);
end

olearn_net_load_str = uicontrol('Style', 'text', 'String', 'Select classifier net:', 'units', 'normalized', 'position', olearn_net_load_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);
olearn_net_load_select = uicontrol('Style', 'popupmenu', 'String', training_nets, 'units', 'normalized', 'position', olearn_net_load_select_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);
olearn_net_load_select.Value = 1;


%% Load data and nets
available_recs = dir(strcat(dataset_dir_name, 'Rec*'));
nrecs = length(available_recs);
available_datasets = {dataset_dir_name};
for nnet = 1:nrecs
    available_datasets{1 + nnet} = available_recs(nnet).name;
end

alearn_data_str = uicontrol('Style', 'text', 'String', 'Select training data:', 'units', 'normalized', 'position', alearn_data_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);
alearn_data_select = uicontrol('Style', 'popupmenu', 'String', available_datasets, 'units', 'normalized', 'position', alearn_data_select_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);
alearn_data_select.Value = 1;
alearn_data_load_button = uicontrol('Style', 'pushbutton', 'String', 'Load training data', 'Callback', 'ml_alearn_get_data', 'units', 'normalized', 'position', alearn_load_button_pos, 'FontSize', bfsize + 4, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
alearn_data_status_ax = axes('position', alearn_load_status_pos, 'xtick', [], 'ytick', [], 'box', 'on');
axis([0 1 0 1])

olearn_data_str = uicontrol('Style', 'text', 'String', 'Select dataset:', 'units', 'normalized', 'position', olearn_data_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);
olearn_data_select = uicontrol('Style', 'popupmenu', 'String', available_datasets, 'units', 'normalized', 'position', olearn_data_select_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);
olearn_data_select.Value = 1;
olearn_data_load_button = uicontrol('Style', 'pushbutton', 'String', 'Load training data', 'Callback', 'ml_olearn_get_data', 'units', 'normalized', 'position', olearn_load_button_pos, 'FontSize', bfsize + 4, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
olearn_data_status_ax = axes('position', olearn_load_status_pos, 'xtick', [], 'ytick', [], 'box', 'on');
axis([0 1 0 1])


%% Alternative load
olearn_late_load_button = uicontrol('Style', 'pushbutton', 'String', 'Late load', 'Callback', 'ml_olearn_late_load', 'units', 'normalized', 'position', olearn_late_load_button_pos, 'FontSize', bfsize + 4, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
olearn_late_load_status_ax = axes('position', olearn_late_load_status_pos, 'xtick', [], 'ytick', [], 'box', 'on');
axis([0 1 0 1])


%% Name
alearn_name_str = uicontrol('Style', 'text', 'String', 'Network name:', 'units', 'normalized', 'position', alearn_name_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);
alearn_name_edit = uicontrol('Style', 'edit', 'String', 'patternrecognizer', 'units', 'normalized', 'position', alearn_name_edit_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);

olrean_name_str = uicontrol('Style', 'text', 'String', 'Network name:', 'units', 'normalized', 'position', olearn_name_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);
olrean_name_edit = uicontrol('Style', 'edit', 'String', 'decisionmaker', 'units', 'normalized', 'position', olearn_name_edit_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);


%% Goal states
olearn_goal_str = uicontrol('Style', 'text', 'String', 'Goal states:', 'units', 'normalized', 'position', olearn_goal_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);
olearn_goal_edit = uicontrol('Style', 'edit', 'String', '', 'units', 'normalized', 'position', olearn_name_edit_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);


%% Speed
alearning_speeds = {'Slow', 'Fast'};
olearning_speeds = {'Slow', 'Fast'};

alearn_speed_str = uicontrol('Style', 'text', 'String', 'Training speed:', 'units', 'normalized', 'position', alearn_speed_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);
alearn_speed_select = uicontrol('Style', 'popupmenu', 'String', alearning_speeds, 'units', 'normalized', 'position', alearn_speed_select_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);

olearn_speed_str = uicontrol('Style', 'text', 'String', 'Training speed:', 'units', 'normalized', 'position', olearn_speed_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);
olearn_speed_select = uicontrol('Style', 'popupmenu', 'String', olearning_speeds, 'units', 'normalized', 'position', olearn_speed_select_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);


%% Train
alearn_train_button = uicontrol('Style', 'pushbutton', 'String', 'Train network', 'Callback', 'ml_alearn_train_net', 'units', 'normalized', 'position', alearn_train_button_pos, 'FontSize', bfsize + 4, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
alearn_train_status_ax = axes('position', alearn_train_status_pos, 'xtick', [], 'ytick', [], 'box', 'on');
axis([0 1 0 1])

olearn_train_button = uicontrol('Style', 'pushbutton', 'String', 'Train network', 'Callback', 'ml_olearn_train_net', 'units', 'normalized', 'position', olearn_train_button_pos, 'FontSize', bfsize + 4, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
olearn_train_status_ax = axes('position', olearn_train_status_pos, 'xtick', [], 'ytick', [], 'box', 'on');
axis([0 1 0 1])


%% Image Panels
im_ax1 = axes('position', im_ax1_pos, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col);


%% Exit button
button_exit_ml = uicontrol('Style', 'pushbutton', 'String', 'Exit ML', 'units', 'normalized', 'position', button_exit_ml_pos);
set(button_exit_ml,'Callback', 'ml_exit_callback', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

