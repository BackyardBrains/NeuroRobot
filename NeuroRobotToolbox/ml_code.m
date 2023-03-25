

% y = [1000 5000]; % nsmall = = 0.01527 * ntuples + 694.7
% y = [2000 10000]; % nmedium = 0.03053 * ntuples + 1389
% y = [100 500]; % treeproperties = = 0.001527 * ntuples + 69.47
% y = [100 300]; % init_n_unique_states = 0.0007634 * ntuples + 84.73
% y = [20 33]; % min_size = 0.00005 * ntuples + 19; 


%% ML settings
nsmall = 5000;
nmedium = 10000;
treeprops = [2 500];
n_unique_states = 300;
min_size = 33;
rec_dir_name = '';


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
init_n_unique_states = n_unique_states;

if ~exist('dataset_dir_name', 'var')
    disp('Running record data prep...')
    record_data_prep_code
end

if ~exist('workspace_dir_name', 'var')
    disp('Running controller prep...')
    controller_prep_code
end


%% Prepare figure
fig_ml = figure(3);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'SpikerBot - Deep Learning')
set(fig_ml, 'menubar', 'none', 'toolbar', 'none')
set(fig_ml, 'position', fig_pos, 'color', fig_bg_col) 


%% Buttons
button1_pos = [0.03 0.87 0.2 0.05];
button2_pos = [0.03 0.8 0.2 0.05];
button3_pos = [0.03 0.73 0.2 0.05];
button4_pos = [0.03 0.66 0.2 0.05];
button5_pos = [0.03 0.59 0.2 0.05];
button6_pos = [0.03 0.52 0.2 0.05];
button7_pos = [0.03 0.45 0.2 0.05];
button8_pos = [0.03 0.38 0.2 0.05];
button9_pos = [0.03 0.31 0.2 0.05];
button10_pos = [0.03 0.24 0.2 0.05];

button_data = uicontrol('Style', 'pushbutton', 'String', 'Get data', 'units', 'normalized', 'position', button1_pos);
set(button_data,'Callback', 'ml_get_data_stats', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_similarity = uicontrol('Style', 'pushbutton', 'String', 'Get similarity scores', 'units', 'normalized', 'position', button2_pos);
set(button_similarity,'Callback', 'ml_get_similarity', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_cluster = uicontrol('Style', 'pushbutton', 'String', 'Cluster similar data', 'units', 'normalized', 'position', button3_pos);
set(button_cluster,'Callback', 'ml_get_clusters', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_prune = uicontrol('Style', 'pushbutton', 'String', 'Quality control', 'units', 'normalized', 'position', button4_pos);
set(button_prune,'Callback', 'ml_prune', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_training_data = uicontrol('Style', 'pushbutton', 'String', 'Finalize training data', 'units', 'normalized', 'position', button5_pos);
set(button_training_data,'Callback', 'ml_finalize_training_data', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_get_net = uicontrol('Style', 'pushbutton', 'String', 'Train state net', 'units', 'normalized', 'position', button6_pos);
set(button_get_net,'Callback', 'ml_get_state_net', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_get_tuples = uicontrol('Style', 'pushbutton', 'String', 'Get tuples', 'units', 'normalized', 'position', button7_pos);
set(button_get_tuples,'Callback', 'ml_get_tuples', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_get_mdp = uicontrol('Style', 'pushbutton', 'String', 'Get Markov Decision Process', 'units', 'normalized', 'position', button8_pos);
set(button_get_mdp,'Callback', 'ml_get_mdp', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_set_goals = uicontrol('Style', 'pushbutton', 'String', 'Set goals', 'units', 'normalized', 'position', button9_pos);
set(button_set_goals,'Callback', 'ml_set_rewards', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_get_agent = uicontrol('Style', 'pushbutton', 'String', 'Train action net', 'units', 'normalized', 'position', button10_pos);
set(button_get_agent,'Callback', 'ml_get_action_net', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])


%% Text Fields
ax1_pos = [0.26 0.87 0.31 0.05];
ax1 = axes('position', ax1_pos);
set(ax1, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ax2_pos = [0.26 0.8 0.31 0.05];
ax2 = axes('position', ax2_pos);
set(ax2, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ax3_pos = [0.26 0.73 0.31 0.05];
ax3 = axes('position', ax3_pos);
set(ax3, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ax4_pos = [0.26 0.66 0.31 0.05];
ax4 = axes('position', ax4_pos);
set(ax4, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ax5_edit_pos = [0.26 0.59 0.12 0.05];
ax5_pos = [0.4 0.59 0.17 0.05];
ax5_edit = uicontrol('Style', 'edit', 'String', 'Enter state net name here', 'units', 'normalized', 'position', ax5_edit_pos);
ax5 = axes('position', ax5_pos);
set(ax5, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ax6_pos = [0.26 0.52 0.31 0.05];
ax6 = axes('position', ax6_pos);
set(ax6, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ax7_pos = [0.26 0.45 0.31 0.05];
ax7 = axes('position', ax7_pos);
set(ax7, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ax8_pos = [0.26 0.38 0.31 0.05];
ax8 = axes('position', ax8_pos);
set(ax8, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ax9_edit_pos = [0.26 0.31 0.12 0.05];
ax9_pos = [0.4 0.31 0.17 0.05];
ax9_edit = uicontrol('Style', 'edit', 'String', 'Enter goal states here', 'units', 'normalized', 'position', ax9_edit_pos);
ax9 = axes('position', ax9_pos);
set(ax9, 'xtick', [], 'ytick', [])
box on
axis([0 1 0 1])

ax10_edit_pos = [0.26 0.24 0.12 0.05];
ax10_pos = [0.4 0.24 0.17 0.05];
ax10_edit = uicontrol('Style', 'edit', 'String', 'Enter action net name here', 'units', 'normalized', 'position', ax10_edit_pos);
ax10 = axes('position', ax10_pos);
set(ax10, 'xtick', [], 'ytick', [])
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

