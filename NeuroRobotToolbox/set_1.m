% Create runtime buttons
button_design = uicontrol('Style', 'pushbutton', 'String', 'Design', 'units', 'normalized', 'position', [0.02 0.02 0.176 0.05]);
set(button_design,'Callback', 'run_button = 1;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_save = uicontrol('Style', 'pushbutton', 'String', 'Save', 'units', 'normalized', 'position', [0.216 0.02 0.176 0.05]);
set(button_save,'Callback', 'run_button = 2;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_pause = uicontrol('Style', 'pushbutton', 'String', 'Restart', 'units', 'normalized', 'position', [0.412 0.02 0.176 0.05]);
set(button_pause,'Callback', 'if run_button ~= 3 run_button = 3; else exit_pause; end', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_stop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0.608 0.02 0.176 0.05]);
set(button_stop,'Callback', 'run_button = 4;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_reward = uicontrol('Style', 'pushbutton', 'String', 'Dopamine', 'units', 'normalized', 'position', [0.804 0.02 0.176 0.05]);
set(button_reward,'Callback', 'run_button = 5;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])