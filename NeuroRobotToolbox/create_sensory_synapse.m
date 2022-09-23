
% disp('Eye contact selected. Launching create_sensory_synapse...')
% disp(horzcat('fig userdata = ', num2str(fig_design.UserData), ...
%     ', presyn clear = ', num2str(~exist('presynaptic_neuron', 'var')), ...
%     ', nneurons = ', num2str(nneurons)))

% If no other design action is in progress
if fig_design.UserData == 0 && ~exist('presynaptic_neuron', 'var') && nneurons
    
%     % Disable unavailable buttons
%     set(button_add_neuron, 'enable', 'off')
%     set(button_add_network, 'enable', 'off')
%     set(button_return_to_runtime, 'enable', 'off')   
    
    % Set current design action
    fig_design.UserData = 6;

    % Initialize presynaptic contact
    presynaptic_contact = selected_contact;
    contact_h(selected_contact).MarkerFaceColor = sel_col_core;
    
    % Text heading
    text_heading = uicontrol('Style', 'text', 'String', 'Select a postsynaptic neuron', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

else

    disp('create_sensory_synapse failed to launch')

end