

%% Lock
disp('Preparing ML interface...')
button_to_sleep.BackgroundColor = [0.94 0.78 0.62];
set(button_camera, 'enable', 'off')
set(button_startup_complete, 'enable', 'off')
set(button_to_simulator, 'enable', 'off')
set(button_to_sleep, 'enable', 'off')
set(button_to_quit, 'enable', 'off')
set(button_new_brain, 'enable', 'off')
drawnow


%% Get settings
available_settings = dir(strcat(settings_dir_name, 'settings.csv'));
if ~isempty(available_settings)
    disp('ML settings found')
else
    disp('No ML settings found')
end


%% Get directories
available_dirs = dir(dataset_dir_name);
available_dirs(1:2) = [];
nrecs = length(available_dirs);

clear dataset_dirs
dataset_dirs{1} = strcat(userpath, '\Datasets\');

if exist('C:\SpikerBot\Livingroom\', 'dir') && ~isempty('C:\SpikerBot\Livingroom\')
    dataset_dirs{2} = 'C:\SpikerBot\Livingroom\';
end

if exist('C:\SpikerBot\LivingroomArena\', 'dir') && ~isempty('C:\SpikerBot\LivingroomArena\')
    dataset_dirs{length(dataset_dirs)+1} = 'C:\SpikerBot\LivingroomArena\';
end

% if exist('C:\SpikerBot\Temp\', 'dir') && ~isempty('C:\SpikerBot\Temp\')
%     dataset_dirs{length(dataset_dirs)+1} = 'C:\SpikerBot\Temp\';
% end


%% Prep
ml_flag = 1;


%% Prepare figure
fig_ml = figure(3);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'SpikerBot - Learning')
set(fig_ml, 'menubar', 'none', 'toolbar', 'none')
set(fig_ml, 'position', fig_pos, 'color', fig_bg_col) 


%% Positions
ml_title_pos =            [0.03 0.9 0.94 0.05];

ml_1_data_str_pos =         [0.05 0.81 0.2 0.05];
ml_1_data_status_pos =      [0.26 0.81 0.28 0.05];

ml_2_name1_str_pos =        [0.05 0.74 0.2 0.05];
ml_2_name1_edit_pos =       [0.26 0.74 0.28 0.05];

ml_3_train1_button_pos =    [0.05 0.67 0.2 0.05];
ml_3_train1_status_pos =    [0.26 0.67 0.28 0.05];

ml_4_train2_button_pos =    [0.05 0.6 0.2 0.05];
ml_4_train2_status_pos =    [0.26 0.6 0.28 0.05];

ml_5_train3_button_pos =    [0.05 0.53 0.2 0.05];
ml_5_train3_status_pos =    [0.26 0.53 0.28 0.05];

ml_6_train4_button_pos =    [0.05 0.46 0.2 0.05];
ml_6_train4_status_pos =    [0.26 0.46 0.28 0.05];

ml_7_load_button_pos =      [0.05 0.39 0.2 0.05];
ml_7_load_status_pos =      [0.26 0.39 0.28 0.05];

ml_8_goals_str_pos =        [0.05 0.32 0.2 0.05];
ml_8_goals_edit_pos =       [0.26 0.32 0.28 0.05];

ml_9_name2_str_pos =        [0.05 0.25 0.2 0.05];
ml_9_name2_edit_pos =       [0.26 0.25 0.28 0.05];

ml_10_train2_button_pos =    [0.05 0.18 0.2 0.05];
ml_10_train2_status_pos =    [0.26 0.18 0.28 0.05];

ml_11_advanced_button_pos =    [0.05 0.08 0.2 0.05];


%% UI objects
ml_title = uicontrol('Style', 'text', 'String', 'Learning', 'units', 'normalized', 'position', ml_title_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 12, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

ml_data_str = uicontrol('Style', 'text', 'String', 'Data source:', 'units', 'normalized', 'position', ml_1_data_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'right', 'fontweight', gui_font_weight);
ml_data_status = uicontrol('Style', 'popupmenu', 'String', dataset_dirs, 'callback', 'dataset_dir_name = dataset_dirs{ml_data_status.Value};', 'units', 'normalized', 'position', ml_1_data_status_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);

ml_name1_str = uicontrol('Style', 'text', 'String', 'Classifier network name:', 'units', 'normalized', 'position', ml_2_name1_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'right', 'fontweight', gui_font_weight);
ml_name1_edit = uicontrol('Style', 'edit', 'String', '', 'units', 'normalized', 'position', ml_2_name1_edit_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);

ml_train1_button = uicontrol('Style', 'pushbutton', 'String', 'Train new network', 'Callback', 'ml_step1', 'units', 'normalized', 'position', ml_3_train1_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
ml_train1_status = axes('position', ml_3_train1_status_pos, 'xtick', [], 'ytick', []);
box on
axis([0 1 0 1])

ml_train2_button = uicontrol('Style', 'pushbutton', 'String', 'Continue from clustered data', 'Callback', 'ml_flag = 2; ml_step1', 'units', 'normalized', 'position', ml_4_train2_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
ml_train2_status = axes('position', ml_4_train2_status_pos, 'xtick', [], 'ytick', []);
box on
axis([0 1 0 1])

ml_train3_button = uicontrol('Style', 'pushbutton', 'String', 'Continue from trained convnet', 'Callback', 'ml_flag = 3; ml_step1', 'units', 'normalized', 'position', ml_5_train3_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
ml_train3_status = axes('position', ml_5_train3_status_pos, 'xtick', [], 'ytick', []);
box on
axis([0 1 0 1])

ml_train4_button = uicontrol('Style', 'pushbutton', 'String', 'Continue from states and commands', 'Callback', 'ml_flag = 4; ml_step1', 'units', 'normalized', 'position', ml_6_train4_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
ml_train4_status = axes('position', ml_6_train4_status_pos, 'xtick', [], 'ytick', []);
box on
axis([0 1 0 1])

ml_load_button = uicontrol('Style', 'pushbutton', 'String', 'Load MDP', 'Callback', 'ml_load', 'units', 'normalized', 'position', ml_7_load_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
ml_load_status = axes('position', ml_7_load_status_pos, 'xtick', [], 'ytick', []);
box on
axis([0 1 0 1])

ml_goals_str = uicontrol('Style', 'text', 'String', 'Goal states:', 'units', 'normalized', 'position', ml_8_goals_str_pos, 'fontsize', bfsize + 4);
ml_goals_edit = uicontrol('Style', 'edit', 'String', '', 'units', 'normalized', 'position', ml_8_goals_edit_pos, 'fontsize', bfsize + 4);

ml_name2_str = uicontrol('Style', 'text', 'String', 'Decision network name:', 'units', 'normalized', 'position', ml_9_name2_str_pos, 'fontsize', bfsize + 4);
ml_name2_edit = uicontrol('Style', 'edit', 'String', '', 'units', 'normalized', 'position', ml_9_name2_edit_pos, 'fontsize', bfsize + 4);

ml_train5_button = uicontrol('Style', 'pushbutton', 'String', 'Train decision network', 'Callback', 'ml_step2', 'units', 'normalized', 'position', ml_10_train2_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
ml_train5_status = axes('position', ml_10_train2_status_pos, 'xtick', [], 'ytick', []);
box on
axis([0 1 0 1])

ml_custom_button = uicontrol('Style', 'pushbutton', 'String', 'Custom net', 'Callback', 'ml_custom_net', 'units', 'normalized', 'position', ml_11_advanced_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);


%% Image Panels
im_ax1_pos = [0.58 0.2 0.39 0.65];
im_ax1 = axes('position', im_ax1_pos);
set(im_ax1, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)
disp('Ready to train')


%% Exit button
button_advanced_ml_pos = [0.58 0.04 0.37 0.05];
button_advanced_ml = uicontrol('Style', 'pushbutton', 'String', 'Main Menu', 'units', 'normalized', 'position', button_advanced_ml_pos);
set(button_advanced_ml,'Callback', 'ml_exit_callback', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])


%% Get settings
if ~isempty(available_settings)
    settings_fname = horzcat(available_settings(1).folder, '\', available_settings(1).name);
    disp(horzcat('Loading settings: ', settings_fname))
    try
        raw_settings = readtable(settings_fname);
        nparams = size(raw_settings, 1);
        for nparam = 1:nparams
            expression = char(strcat(raw_settings{nparam, 2}, '=', num2str(raw_settings{nparam, 3}), ';'));
            eval(expression);
        end        
    catch
        disp('Cannot read settings')
    end
else
    disp('Cannot load settings')
end

