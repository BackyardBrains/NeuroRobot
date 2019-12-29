
%%% EXERCISES


%% Prepare figure
fig_exercises = figure(5);
clf
set(fig_exercises, 'NumberTitle', 'off', 'Name', 'Neurorobot Exercises')
set(fig_exercises, 'menubar', 'none', 'toolbar', 'none')
set(fig_exercises, 'position', startup_fig_pos, 'color', fig_bg_col) 

% Title
exercises_text_title = uicontrol('Style', 'text', 'String', 'Neurorobot Exercises', 'units', 'normalized', 'position', [0.05 0.9 0.9 0.05], ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 10, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

% Select exercise
exercises_text_load = uicontrol('Style', 'text', 'String', 'Select exercise', 'units', 'normalized', 'position', [0.05 0.8 0.35 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 8, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
clear exercise_string
exercise_string{1} = '-- Create new exercise --';
exercise_directory = './Exercises/*.mat';
available_exercises = dir(exercise_directory);
nexercises = size(available_exercises, 1);
for nexercise = 1:nexercises
    exercise_string{nexercise + 1} = available_exercises(nexercise).name(1:end-4);
end
popup_select_exercise = uicontrol('Style', 'popup', 'String', exercise_string, 'callback', 'update_exercise_name_edit', 'units', 'normalized', ...
    'position', [0.05 0.7 0.35 0.1], 'fontsize', bfsize + 8, 'fontweight', gui_font_weight, 'FontName', gui_font_name);
if ~restarting
    exercise_name = '';
end
text_name = uicontrol('Style', 'text', 'String', 'exercise name', 'units', 'normalized', 'position', [0.05 0.67 0.35 0.05], ....
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 8, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
edit_name = uicontrol('Style', 'edit', 'String', exercise_name, 'units', 'normalized', 'position', [0.05 0.57 0.35 0.1], 'fontsize', bfsize + 10, ....
    'FontName', gui_font_name, 'fontweight', gui_font_weight);

% Select exercise button
if (exist('rak_fail', 'var') && ~rak_fail && exist('rak_pulse', 'var') && isvalid(rak_pulse) && strcmp(rak_pulse.Running, 'on')) ...
        && ~(exist('rak_cam', 'var') && ~rak_cam.isRunning)
    this_col = [0.6 0.95 0.6];
elseif (exist('rak_fail', 'var') && rak_fail) || (exist('rak_pulse', 'var') && isvalid(rak_pulse) && strcmp(rak_pulse.Running, 'off'))
    this_col = [1 0.5 0.5];
else
    this_col = [0.8 0.8 0.8];
end
button_select = uicontrol('Style', 'pushbutton', 'String', 'Select exercise', 'units', 'normalized', 'position', [0.05 0.38 0.35 0.07]);
set(button_select, 'Callback', 'this_exercise = exercise_name; close(fig_exercises)', 'FontSize', bfsize + 10, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', this_col)

% Cancel button
button_cancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'units', 'normalized', 'position', [0.05 0.28 0.35 0.07]);
set(button_cancel, 'Callback', 'close(fig_exercises); ', 'FontSize', bfsize + 8, 'FontName', gui_font_name, ...
    'FontWeight', gui_font_weight, 'BackgroundColor', this_col)

% Exercise info display
exercise_info_ax = axes('position', [0.475 0.1 0.45 0.75]);
set(exercise_info_ax, 'xtick', [], 'ytick', [], 'xcolor', 'k', 'ycolor', 'k')
hold on
box on
for nexercise = 1:10
    ex_text_line(nexercise) = text(-0.5, 10 - nexercise, '');
end

axis([-1 10 -1 10])


