
% Command log
if save_data_and_commands
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    command_log.entry(command_log.n).time = this_time;    
    command_log.entry(command_log.n).action = 'attach script';
    command_log.n = command_log.n + 1;
end

% Remove select neuron menu
delete(text_heading)
delete(button1)
delete(button2)
delete(button3)
delete(button4)
delete(button5)
delete(button_cancel)

% Design action: edit properties / assign script
fig_design.UserData = 3;

text_heading = uicontrol('Style', 'text', 'String', 'Select script', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

popup_select_script = uicontrol('Style', 'popup', 'String', script_names, 'units', 'normalized', 'position', [0.02 0.85 0.16 0.06], 'fontsize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
% if existing_pref
%     popup_select_preference.Value = find(vis_prefs(postsynaptic_neuron, :, presynaptic_contact));
% end

% Option to delete existing sensory synapse
% delete_synapse = 0;
% button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize, 'BackgroundColor', [0.8 0.8 0.8]);
% set(button_confirm, 'Callback', 'fig_design.UserData = 0;')         
% if existing_pref
%     button_stop = uicontrol('Style', 'pushbutton', 'String', 'Delete existing synapse', 'units', 'normalized', 'position', [0.02 0.69 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize, 'BackgroundColor', [0.8 0.8 0.8]);
%     set(button_stop, 'Callback', 'fig_design.UserData = 0; delete_synapse = 1;')
% else
%     button_stop = uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'units', 'normalized', 'position', [0.02 0.69 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize, 'BackgroundColor', [0.8 0.8 0.8]);
%     set(button_stop, 'Callback', 'fig_design.UserData = 0; delete_synapse = 1;')            
% end
        
% Wait for OK
button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06]);
set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
waitfor(fig_design, 'UserData', 0)
delete(button_confirm)
design_action = 0;

% Execute
neuron_scripts(presynaptic_neuron, 1) = popup_select_script.Value;
delete(popup_select_script)

% Restore neuron color
draw_neuron_edge.CData(presynaptic_neuron, :) = [0 0 0];
draw_neuron_core.CData(presynaptic_neuron, :) = neuron_cols(presynaptic_neuron, :);

% Clear neurons
clear presynaptic_neuron

if ~exist('presynaptic_neuron', 'var')
    set(button_add_neuron, 'enable', 'on')
    set(button_add_network, 'enable', 'on')
    set(button_return_to_runtime, 'enable', 'on')
end
