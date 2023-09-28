
% Command log
if save_data_and_commands
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    command_log.entry(command_log.n).time = this_time;    
    command_log.entry(command_log.n).action = 'extend axon';
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

drawnow

if ~da_rew_neurons(presynaptic_neuron)
    
    % Design action: extend axon
    fig_design.UserData = 2;
    design_action = 2;

    % Text
    text_heading = uicontrol('Style', 'text', 'String', 'Where do you want to create a synapse?', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

    % Extend axons
    x = neuron_xys(presynaptic_neuron, 1);
    y = neuron_xys(presynaptic_neuron, 2);
    growth_cone(1) = plot([x - 0.1 x - 0.2], [y - 0.1 y - 0.2], 'linewidth', 2, 'color', sel_col_edge);
    growth_cone(2) = plot([x + 0.1 x + 0.2], [y - 0.1 y - 0.2], 'linewidth', 2, 'color', sel_col_edge);
    growth_cone(3) = plot([x + 0.1 x + 0.2], [y + 0.1 y + 0.2], 'linewidth', 2, 'color', sel_col_edge);
    growth_cone(4) = plot([x - 0.1 x - 0.2], [y + 0.1 y + 0.2], 'linewidth', 2, 'color', sel_col_edge);

else
    
    disp('Dopainergic and medium spiny neurons cannot extend synapses yet')

    % Reset
    draw_neuron_edge.CData(presynaptic_neuron, :) = [0 0 0];
    draw_neuron_core.CData(presynaptic_neuron, :) = neuron_cols(presynaptic_neuron, :);    
    clear presynaptic_neuron
    
end

