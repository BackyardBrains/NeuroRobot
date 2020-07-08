
% Command log
if save_data_and_commands
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    command_log.entry(command_log.n).time = this_time;    
    command_log.entry(command_log.n).action = 'edit properties';
    command_log.n = command_log.n + 1;
end

% Remove select neuron menu
delete(text_heading)
delete(button1)
delete(button2)
delete(button3)
delete(button4)
delete(button_cancel)

% Design action: edit properties
fig_design.UserData = 3;

% Get current properties
this_a = a(presynaptic_neuron);
this_b = b(presynaptic_neuron);
this_c = c(presynaptic_neuron);
this_d = d(presynaptic_neuron);
this_id = network_ids(presynaptic_neuron);
col = neuron_cols(presynaptic_neuron, :);

% Open selection props
% Heading 
text_heading = uicontrol('Style', 'text', 'String', 'Select neuron properties', 'units', 'normalized', 'position', [0.02 0.95 0.29 0.03], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

% Type 1 button
button_n1 = uicontrol('Style', 'pushbutton', 'String', 'Quiet', 'units', 'normalized', 'position', [0.02 0.9 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_n1, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
% Type 2 button
button_n2 = uicontrol('Style', 'pushbutton', 'String', 'Occasionally active', 'units', 'normalized', 'position', [0.02 0.84 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_n2, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
% Type 3 button
button_n3 = uicontrol('Style', 'pushbutton', 'String', 'Highly active', 'units', 'normalized', 'position', [0.02 0.78 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_n3, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
% Type 4 button
button_n4 = uicontrol('Style', 'pushbutton', 'String', 'Generates bursts', 'units', 'normalized', 'position', [0.02 0.72 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_n4, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
% Type 5 button
button_n5 = uicontrol('Style', 'pushbutton', 'String', 'Bursts when activated', 'units', 'normalized', 'position', [0.02 0.66 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_n5, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
% Type 6 button
button_n6 = uicontrol('Style', 'pushbutton', 'String', 'Dopaminergic', 'units', 'normalized', 'position', [0.02 0.6 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_n6, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
% Type 7 button
button_n7 = uicontrol('Style', 'pushbutton', 'String', 'Basal ganglia', 'units', 'normalized', 'position', [0.02 0.54 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_n7, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])


% Indicate neuron type
if isequal(col, [1 0.9 0.8]) % If quiet
    set(button_n1, 'BackgroundColor', [0.6 0.95 0.6])
elseif isequal(col, [1 0.8 0.6])
    set(button_n2, 'BackgroundColor', [0.6 0.95 0.6])
elseif isequal(col, [1 0.8 0.8])
    set(button_n3, 'BackgroundColor', [0.6 0.95 0.6])
elseif isequal(col, [1 0.6 0.6])
    set(button_n4, 'BackgroundColor', [0.6 0.95 0.6])
elseif isequal(col, [0.9 0.7 1])
    set(button_n5, 'BackgroundColor', [0.6 0.95 0.6])
elseif isequal(col, [0.8 0.8 1])
    set(button_n6, 'BackgroundColor', [0.6 0.95 0.6])
elseif isequal(col, [0.95 0.95 1])
    set(button_n7, 'BackgroundColor', [0.6 0.95 0.6])    
end
    
% A
text_a = uicontrol('Style', 'text', 'String', 'a', 'units', 'normalized', 'position', [0.02 0.46 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_a = uicontrol('Style', 'edit', 'String', num2str(this_a), 'units', 'normalized', 'position', [0.03 0.46 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
% B
text_b = uicontrol('Style', 'text', 'String', 'b', 'units', 'normalized', 'position', [0.07 0.46 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_b = uicontrol('Style', 'edit', 'String', num2str(this_b), 'units', 'normalized', 'position', [0.08 0.46 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
% C
text_c = uicontrol('Style', 'text', 'String', 'c', 'units', 'normalized', 'position', [0.12 0.46 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_c = uicontrol('Style', 'edit', 'String', num2str(this_c), 'units', 'normalized', 'position', [0.13 0.46 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
% D
text_d = uicontrol('Style', 'text', 'String', 'd', 'units', 'normalized', 'position', [0.17 0.46 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_d = uicontrol('Style', 'edit', 'String', num2str(this_d), 'units', 'normalized', 'position', [0.18 0.46 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
% ID
text_id = uicontrol('Style', 'text', 'String', 'id', 'units', 'normalized', 'position', [0.23 0.46 0.02 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_id = uicontrol('Style', 'edit', 'String', num2str(this_id), 'units', 'normalized', 'position', [0.25 0.46 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

% Wait for OK
button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.38 0.26 0.06]);
set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
waitfor(fig_design, 'UserData', 0)
delete(button_confirm)
design_action = 0;

% Update parameters
a(presynaptic_neuron) = str2double(edit_a.String);
b(presynaptic_neuron) = str2double(edit_b.String);
c(presynaptic_neuron) = str2double(edit_c.String);
d(presynaptic_neuron) = str2double(edit_d.String);
neuron_cols(presynaptic_neuron, 1:3) = col;
network_ids(presynaptic_neuron) = str2double(edit_id.String);
nnetworks = length(unique(network_ids)); % There used to be a +1 hack here, removing, testing..
network_drive = zeros(nnetworks, 3);

% Remove menu
delete(text_heading)
delete(text_a)
delete(edit_a)
delete(text_b)
delete(edit_b)
delete(text_c)
delete(edit_c)
delete(text_d)
delete(edit_d)
delete(text_id)
delete(edit_id)

delete(button_n1)
delete(button_n2)
delete(button_n3)
delete(button_n4)
delete(button_n5)
delete(button_n6)
delete(button_n7)

% Restore neuron color
draw_neuron_edge.CData(presynaptic_neuron, :) = [0 0 0];
draw_neuron_core.CData(presynaptic_neuron, :) = col;

% Clear neurons
clear presynaptic_neuron

