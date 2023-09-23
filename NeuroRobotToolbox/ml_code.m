

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


%% Prepare
% rec_dir_name = 'Rec3';
rec_dir_name = '';


%% Prepare figure
fig_ml = figure(3);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'SpikerBot - Learning')
set(fig_ml, 'menubar', 'none', 'toolbar', 'none')
set(fig_ml, 'position', fig_pos, 'color', fig_bg_col) 


%% Buttons
ml_title_pos = [0.03 0.58 0.2 0.05];
ml_button1_pos = [0.03 0.52 0.2 0.05];
ml_button2_pos = [0.03 0.45 0.2 0.05];
ml_button3_pos = [0.03 0.38 0.2 0.05];
ml_out1_pos = [0.26 0.52 0.31 0.05];
ml_out2_pos = [0.26 0.45 0.31 0.05];
ml_out3_pos = [0.49 0.38 0.08 0.05];
ml_edit3_goal_pos = [0.39 0.38 0.09 0.05];
ml_edit3_name_pos = [0.26 0.38 0.12 0.05];

ml_title = uicontrol('Style', 'text', 'String', 'Learning', 'units', 'normalized', 'position', ml_title_pos, ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

button_data_ml = uicontrol('Style', 'pushbutton', 'String', 'Get state net and MDP', 'units', 'normalized', 'position', ml_button1_pos);
set(button_data_ml,'Callback', 'ml_step1', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_load_ml = uicontrol('Style', 'pushbutton', 'String', 'Load state net and MDP', 'units', 'normalized', 'position', ml_button2_pos);
set(button_load_ml,'Callback', 'ml_load', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_train_ml = uicontrol('Style', 'pushbutton', 'String', 'Train action net', 'units', 'normalized', 'position', ml_button3_pos);
set(button_train_ml,'Callback', 'ml_step2', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])


%% Text Fields
ml_out1 = axes('position', ml_out1_pos);
set(ml_out1, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ml_out2 = axes('position', ml_out2_pos);
set(ml_out2, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ml_out3 = axes('position', ml_out3_pos);
set(ml_out3, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ml_edit3_goal = uicontrol('Style', 'edit', 'String', 'Enter goal states here', 'units', 'normalized', 'position', ml_edit3_goal_pos);
ml_edit3_name = uicontrol('Style', 'edit', 'String', 'Enter action net name here', 'units', 'normalized', 'position', ml_edit3_name_pos);



%% Exit button
button_exit_ml_pos = [0.03 0.08 0.2 0.05];
button_exit_ml = uicontrol('Style', 'pushbutton', 'String', 'Exit ML', 'units', 'normalized', 'position', button_exit_ml_pos);
set(button_exit_ml,'Callback', 'ml_exit_callback', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])


%% Image Panels
im_ax1_pos = [0.63 0.54 0.3 0.35];
im_ax1_colb_pos = [0.94 0.54 0.02 0.35];
im_ax1 = axes('position', im_ax1_pos);
set(im_ax1, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)

im_ax2_pos = [0.63 0.08 0.3 0.35];
im_ax2_colb_pos = [0.94 0.08 0.02 0.35];
im_ax2 = axes('position', im_ax2_pos);
set(im_ax2, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)

disp('Ready to train')

