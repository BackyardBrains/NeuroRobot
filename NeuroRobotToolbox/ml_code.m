

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


%% Prepare
% rec_dir_name = 'Rec3';
rec_dir_name = 'wallArena';


%% Prepare figure
fig_ml = figure(3);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'SpikerBot - Learning')
set(fig_ml, 'menubar', 'none', 'toolbar', 'none')
set(fig_ml, 'position', fig_pos, 'color', fig_bg_col) 


%% Positions
ml_1_title_pos =            [0.03 0.9 0.94 0.05];
ml_2_data_str_pos =         [0.03 0.8 0.2 0.05];
ml_2_data_status_pos =      [0.26 0.8 0.28 0.05];
ml_3_speed_str_pos =        [0.03 0.7 0.2 0.05];
ml_3_speed_select_pos =     [0.26 0.7 0.28 0.05];
ml_4_name1_str_pos =        [0.03 0.6 0.2 0.05];
ml_4_name1_edit_pos =       [0.26 0.6 0.28 0.05];
ml_5_train1_button_pos =    [0.03 0.5 0.2 0.05];
ml_5_train1_status_pos =    [0.26 0.5 0.28 0.05];
ml_6_load_button_pos =      [0.03 0.4 0.2 0.05];
ml_6_load_status_pos =      [0.26 0.4 0.28 0.05];
ml_7_goals_str_pos =        [0.03 0.3 0.2 0.05];
ml_7_goals_edit_pos =       [0.26 0.3 0.28 0.05];
ml_8_name2_str_pos =        [0.03 0.2 0.2 0.05];
ml_8_name2_edit_pos =       [0.26 0.2 0.28 0.05];
ml_9_train2_button_pos =    [0.03 0.1 0.2 0.05];
ml_9_train2_status_pos =    [0.26 0.1 0.28 0.05];


%% UI objects
ml_title = uicontrol('Style', 'text', 'String', 'Learning', 'units', 'normalized', 'position', ml_1_title_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 8, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

available_dirs = dir(dataset_dir_name);
available_dirs(1:2) = [];
ml_data_str = uicontrol('Style', 'text', 'String', 'Data source:', 'units', 'normalized', 'position', ml_2_data_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'right', 'fontweight', gui_font_weight);
ml_data_status = uicontrol('Style', 'popupmenu', 'String', {dataset_dir_name, available_dirs.name}, 'units', 'normalized', 'position', ml_2_data_status_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);

ml_speeds = {'Slow', 'Medium', 'Fast'};
ml_speed_str = uicontrol('Style', 'text', 'String', 'Training speed:', 'units', 'normalized', 'position', ml_3_speed_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'right', 'fontweight', gui_font_weight);
ml_speed_select = uicontrol('Style', 'popupmenu', 'String', ml_speeds, 'units', 'normalized', 'position', ml_3_speed_select_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);

ml_name1_str = uicontrol('Style', 'text', 'String', 'Classifier network name:', 'units', 'normalized', 'position', ml_4_name1_str_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'right', 'fontweight', gui_font_weight);
ml_name1_edit = uicontrol('Style', 'edit', 'String', '', 'units', 'normalized', 'position', ml_4_name1_edit_pos, 'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight);

ml_train1_button = uicontrol('Style', 'pushbutton', 'String', 'Train classifier network', 'Callback', 'ml_step1', 'units', 'normalized', 'position', ml_5_train1_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
ml_train1_status = axes('position', ml_5_train1_status_pos, 'xtick', [], 'ytick', []);
box on
axis([0 1 0 1])

ml_load_button = uicontrol('Style', 'pushbutton', 'String', 'Load classifier network', 'Callback', 'ml_load', 'units', 'normalized', 'position', ml_6_load_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
ml_load_status = axes('position', ml_6_load_status_pos, 'xtick', [], 'ytick', []);
box on
axis([0 1 0 1])

ml_goals_str = uicontrol('Style', 'text', 'String', 'Goal states:', 'units', 'normalized', 'position', ml_7_goals_str_pos, 'fontsize', bfsize + 4);
ml_goals_edit = uicontrol('Style', 'edit', 'String', '', 'units', 'normalized', 'position', ml_7_goals_edit_pos, 'fontsize', bfsize + 4);

ml_name2_str = uicontrol('Style', 'text', 'String', 'Decision network name:', 'units', 'normalized', 'position', ml_8_name2_str_pos, 'fontsize', bfsize + 4);
ml_name2_edit = uicontrol('Style', 'edit', 'String', '', 'units', 'normalized', 'position', ml_8_name2_edit_pos, 'fontsize', bfsize + 4);

ml_train2_button = uicontrol('Style', 'pushbutton', 'String', 'Train decision network', 'Callback', 'ml_step2', 'units', 'normalized', 'position', ml_9_train2_button_pos, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]);
ml_train2_status = axes('position', ml_9_train2_status_pos, 'xtick', [], 'ytick', []);
box on
axis([0 1 0 1])


%% Image Panels
im_ax1_pos = [0.58 0.2 0.39 0.65];
im_ax1 = axes('position', im_ax1_pos);
set(im_ax1, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)

disp('Ready to train')


% %% Advanced settings button
% button_exit_ml_pos = [0.75 0.11 0.2 0.05];
% button_exit_ml = uicontrol('Style', 'pushbutton', 'String', 'Advanced Settings', 'units', 'normalized', 'position', button_exit_ml_pos);
% set(button_exit_ml,'Callback', 'ml_interface', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])


%% Exit button
button_advanced_ml_pos = [0.75 0.04 0.2 0.05];
button_advanced_ml = uicontrol('Style', 'pushbutton', 'String', 'Main Menu', 'units', 'normalized', 'position', button_advanced_ml_pos);
set(button_advanced_ml,'Callback', 'ml_exit_callback', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
