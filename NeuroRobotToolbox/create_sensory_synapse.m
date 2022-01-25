
disp('Left eye contact selected. Launching create_sensory_synapse...')
disp(horzcat('fig userdata = ', num2str(fig_design.UserData), ...
    ', presyn clear = ', num2str(~exist('presynaptic_neuron', 'var')), ...
    ', nneurons = ', num2str(nneurons)))

% If no other design action is in progress
if fig_design.UserData == 0 && ~exist('presynaptic_neuron', 'var') && nneurons
    
    % Disable unavailable buttons
    set(button_add_neuron, 'enable', 'off')
    set(button_add_network, 'enable', 'off')
    set(button_return_to_runtime, 'enable', 'off')   
    
    % Set current design action
    fig_design.UserData = 6;

    % Find the current input contact
    mouse_location = get(gca, 'CurrentPoint');
    x = mouse_location(1,1);
    y = mouse_location(1,2);
    for ncontact = [1 2 3 5]
        xdist = contact_xys(ncontact, 1) - x;
        ydist = contact_xys(ncontact, 2) - y;  
        sdist = sqrt(xdist^2 + ydist^2);        
        if sdist < 0.4
            presynaptic_contact = ncontact;
            contact_h(ncontact).MarkerFaceColor = sel_col_core;
            disp(horzcat('x = ', num2str(x), ', y = ', num2str(y), ...
                ', sdist = ', num2str(sdist), ', ncontact = ', num2str(ncontact)))
        end
    end
    
    % Text heading
    text_heading = uicontrol('Style', 'text', 'String', 'Select a postsynaptic neuron', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

    disp('End of create_sensory_synapse')

else

    disp('create_sensory_synapse failed to launch')

end