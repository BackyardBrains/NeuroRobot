

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
unsup_title_pos = [0.03 0.86 0.2 0.05];
unsup_button1_pos = [0.03 0.8 0.2 0.05];
unsup_out1_pos = [0.26 0.8 0.31 0.05];
unsup_button2_pos = [0.03 0.73 0.2 0.05];
unsup_edit2_pos = [0.26 0.73 0.14 0.05];
unsup_out2_pos = [0.43 0.73 0.14 0.05];

rl_title_pos = [0.03 0.58 0.2 0.05];
rl_button1_pos = [0.03 0.52 0.2 0.05];
rl_out1_pos = [0.26 0.52 0.31 0.05];
rl_button2_pos = [0.03 0.45 0.2 0.05];
rl_edit2_goal_pos = [0.4 0.45 0.07 0.05];
rl_edit2_name_pos = [0.26 0.45 0.12 0.05];
rl_out2_pos = [0.49 0.45 0.08 0.05];

unsup_title = uicontrol('Style', 'text', 'String', 'Unsupervised Learning', 'units', 'normalized', 'position', unsup_title_pos, ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

button_data_unsup = uicontrol('Style', 'pushbutton', 'String', 'Prepare Data', 'units', 'normalized', 'position', unsup_button1_pos);
set(button_data_unsup,'Callback', 'ml_get_data_unsup', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_train_unsup = uicontrol('Style', 'pushbutton', 'String', 'Train Network', 'units', 'normalized', 'position', unsup_button2_pos);
set(button_train_unsup,'Callback', 'ml_train_net_unsup', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

rl_title = uicontrol('Style', 'text', 'String', 'Reinforcement Learning', 'units', 'normalized', 'position', rl_title_pos, ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 6, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

button_data_rl = uicontrol('Style', 'pushbutton', 'String', 'Prepare data', 'units', 'normalized', 'position', rl_button1_pos);
set(button_data_rl,'Callback', 'ml_get_data_rl', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_train_rl = uicontrol('Style', 'pushbutton', 'String', 'Train Network', 'units', 'normalized', 'position', button7_pos);
set(button_train_rl,'Callback', 'ml_train_net_rl', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])


%% Text Fields
unsup_out1_ax = axes('position', unsup_out1_pos);
set(unsup_out1_ax, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

unsup_edit2 = uicontrol('Style', 'edit', 'String', 'Enter state net name here', 'units', 'normalized', 'position', unsup_edit2_pos);
unsup_out2 = axes('position', unsup_out2_pos);
set(unsup_out2, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

rl_out1 = axes('position', rl_out1_pos);
set(rl_out1, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

rl_edit2_goal = uicontrol('Style', 'edit', 'String', 'Enter goal states here', 'units', 'normalized', 'position', rl_edit2_goal_pos);
rl_edit2_name = uicontrol('Style', 'edit', 'String', 'Enter action net name here', 'units', 'normalized', 'position', rl_edit2_name_pos);
rl_out2 = axes('position', rl_out2_pos);
set(rl_out2, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])


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

