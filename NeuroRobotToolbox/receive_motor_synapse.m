
if fig_design.UserData == 2 && (~exist('postsynaptic_neuron', 'var') && ~exist('postsynaptic_contact', 'var'))

    % Log command
    if save_data_and_commands
        this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
        command_log.entry(command_log.n).time = this_time;            
        command_log.entry(command_log.n).action = 'create neuron to motor synapse';
        command_log.n = command_log.n + 1;
    end
            
    % Delete previous heading
    delete(text_heading)
    
    % Adjust postsynaptic contact
    postsynaptic_contact = selected_contact;
    contact_h(ncontact).MarkerFaceColor = sel_col_core;
    
    this_val = 1;
    
    % Text
    text_heading = uicontrol('Style', 'text', 'String', 'Create (default) or delete synapse', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

    % Connect
    button_w1 = uicontrol('Style', 'pushbutton', 'String', 'Create motor synapse', 'units', 'normalized', 'position', [0.02 0.85 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button_w1, 'Callback', 'set_synapse_type', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.6 0.95 0.6])

    % Remove
    button_w2 = uicontrol('Style', 'pushbutton', 'String', 'Delete motor synapse', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button_w2, 'Callback', 'set_synapse_type', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

    % Manual weight
    current_weight = neuron_contacts(presynaptic_neuron, postsynaptic_contact);
    if current_weight == 0
        current_weight = 50;
    end
    text_w = uicontrol('Style', 'text', 'String', 'Weight:', 'units', 'normalized', 'position', [0.02 0.69 0.16 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    edit_w = uicontrol('Style', 'edit', 'String', num2str(current_weight), 'units', 'normalized', 'position', [0.18 0.69 0.09 0.05], 'fontsize', bfsize + 4 - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);    

    % Wait for OK        
    button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.61 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
    waitfor(fig_design, 'UserData', 0)
    delete(button_confirm)    
    
    % Update variables
    this_input = str2double(edit_w.String);
    if ~isa(this_input, 'double') || this_input < 0
        this_input = 0;
        disp('Motor synapse weight not a positive number. Automatically set to 0.')
    end

    if this_input > 100
        this_input = 100;
        disp('Motor synapse out of range. Automatically set to 100.')
    end

    neuron_contacts(presynaptic_neuron, postsynaptic_contact) = this_input;
    % if  postsynaptic_contact == 6
    %     neuron_contacts(presynaptic_neuron, 8) = this_input;
    % elseif  postsynaptic_contact == 7
    %     neuron_contacts(presynaptic_neuron, 9) = this_input;
    % elseif  postsynaptic_contact == 8
    %     neuron_contacts(presynaptic_neuron, 6) = this_input;
    % elseif  postsynaptic_contact == 9
    %     neuron_contacts(presynaptic_neuron, 7) = this_input;
    % elseif  postsynaptic_contact == 10
    %     neuron_contacts(presynaptic_neuron, 12) = this_input;
    % elseif  postsynaptic_contact == 11
    %     neuron_contacts(presynaptic_neuron, 13) = this_input;
    % elseif  postsynaptic_contact == 12
    %     neuron_contacts(presynaptic_neuron, 10) = this_input;
    % elseif  postsynaptic_contact == 13
    %     neuron_contacts(presynaptic_neuron, 11) = this_input;
    % end

    % Design action complete
    design_action = 0; % not read at the end, ugly hack

    % Delete buttons
    delete(button_w1)
    delete(button_w2)
    delete(text_w)
    delete(edit_w)

    % Delete previous heading
    delete(text_heading)  

    % Delete growth cone
    delete(growth_cone)
    
    % Draw brain
    draw_brain 

    % Clear neurons
    clear presynaptic_neuron
    clear postsynaptic_contact  

    % Enable design buttons
    design_buttons    
       
end