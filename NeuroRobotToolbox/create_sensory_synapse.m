
% disp('Eye contact selected. Launching create_sensory_synapse...')
% disp(horzcat('fig userdata = ', num2str(fig_design.UserData), ...
%     ', presyn clear = ', num2str(~exist('presynaptic_neuron', 'var')), ...
%     ', nneurons = ', num2str(nneurons)))

% If no other design action is in progress
if fig_design.UserData == 0 && ~exist('presynaptic_neuron', 'var') && nneurons
    
    % Disable Design buttons
    delete(button_add_neuron)
    delete(button_add_population)
    delete(button_add_algorithm)
    delete(button_add_agents)
    delete(button_add_brain)
    delete(button_save)
    delete(button_return_to_runtime)
    
    % Set current design action
    fig_design.UserData = 6;

    % Initialize presynaptic contact
    presynaptic_contact = selected_contact;
    contact_h(selected_contact).MarkerFaceColor = sel_col_core;
    
    % Text heading
    text_heading = uicontrol('Style', 'text', 'String', 'Select target neuron', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

else

    disp('create_sensory_synapse failed to launch')

end