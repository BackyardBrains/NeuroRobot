
if fig_design.UserData == 2 && (~exist('postsynaptic_neuron', 'var') && ~exist('postsynaptic_contact', 'var'))

    % Delete previous heading
    delete(text_heading)
    
    % Find the current motor contact
    mouse_location = get(gca, 'CurrentPoint');
    x = mouse_location(1,1);
    y = mouse_location(1,2);
    for ncontact = 6:13
        xdist = contact_xys(ncontact, 1) - x;
        ydist = contact_xys(ncontact, 2) - y;  
        sdist = sqrt(xdist^2 + ydist^2);        
        if sdist < 0.2        
            postsynaptic_contact = ncontact;
            contact_h(ncontact).MarkerFaceColor = sel_col_core;
        end
    end
    
    this_val = 1;
    
    % Text
    text_heading = uicontrol('Style', 'text', 'String', 'Create (default) or delete synapse', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

    % Connect
    button_w1 = uicontrol('Style', 'pushbutton', 'String', 'Create motor synapse', 'units', 'normalized', 'position', [0.02 0.85 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button_w1, 'Callback', 'set_synapse_type', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.6 0.95 0.6])

    % Remove
    button_w2 = uicontrol('Style', 'pushbutton', 'String', 'Delete motor synapse', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button_w2, 'Callback', 'set_synapse_type', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

    % Manual weight
    current_weight = neuron_contacts(presynaptic_neuron, postsynaptic_contact);
    if current_weight == 0
        current_weight = 250;
    end
    text_w = uicontrol('Style', 'text', 'String', 'Weight (80 to 250):', 'units', 'normalized', 'position', [0.02 0.69 0.16 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    edit_w = uicontrol('Style', 'edit', 'String', num2str(current_weight), 'units', 'normalized', 'position', [0.18 0.69 0.09 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);    

    % Wait for OK        
    button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.61 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
    waitfor(fig_design, 'UserData', 0)
    delete(button_confirm)    
    
    % Update variables
    this_val = str2double(edit_w.String);
    this_val(this_val > 250) = 250;
    this_val(this_val < 0) = 0;
    neuron_contacts(presynaptic_neuron, postsynaptic_contact) = this_val;
    if  postsynaptic_contact == 6
        neuron_contacts(presynaptic_neuron, 8) = this_val;
    elseif  postsynaptic_contact == 7
        neuron_contacts(presynaptic_neuron, 9) = this_val;
    elseif  postsynaptic_contact == 8
        neuron_contacts(presynaptic_neuron, 6) = this_val;
    elseif  postsynaptic_contact == 9
        neuron_contacts(presynaptic_neuron, 7) = this_val;
    elseif  postsynaptic_contact == 10
        neuron_contacts(presynaptic_neuron, 12) = this_val;
    elseif  postsynaptic_contact == 11
        neuron_contacts(presynaptic_neuron, 13) = this_val;
    elseif  postsynaptic_contact == 12
        neuron_contacts(presynaptic_neuron, 10) = this_val;
    elseif  postsynaptic_contact == 13
        neuron_contacts(presynaptic_neuron, 11) = this_val;
    end

    % Design action complete
    design_action = 0; % not read at the end, ugly hack

    % Delete buttons
    delete(button_w1)
    delete(button_w2)
    delete(text_w)
    delete(edit_w)
    
    % Delete growth cone
    delete(growth_cone)
    
    % Delete previous heading
    delete(text_heading)    

    % Draw brain
    draw_brain 

    % Clear neurons
    clear presynaptic_neuron
    clear postsynaptic_contact    
    
end