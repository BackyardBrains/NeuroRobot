
% Command log
this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
command_log.entry(command_log.n).time = this_time;    
command_log.entry(command_log.n).action = 'cancel edit';
command_log.n = command_log.n + 1;

% Remove select neuron menu
delete(text_heading)
delete(button1)
delete(button2)
delete(button3)
delete(button4)
delete(button_cancel)

% Restore color
draw_neuron_edge.CData(presynaptic_neuron, :) = [0 0 0];
draw_neuron_core.CData(presynaptic_neuron, :) = neuron_cols(presynaptic_neuron, :);

% Clear neuron selection
clear presynaptic_neuron