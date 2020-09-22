
if fig_design.UserData == 2 && (~exist('postsynaptic_neuron', 'var') && ~exist('postsynaptic_contact', 'var'))

    % Log command
    if save_data_and_commands
        this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
        command_log.entry(command_log.n).time = this_time;            
        command_log.entry(command_log.n).action = 'create neuron to speaker synapse';
        command_log.n = command_log.n + 1;
    end
            
    % Delete previous heading
    delete(text_heading)
    
    % Activate speaker contact
    contact_h(4).MarkerFaceColor = sel_col_core;  
    speaker_selected = 1;
%     this_val = 1000; % 2020-07-30 rem
    
    % Text
    text_heading = uicontrol('Style', 'text', 'String', 'Set or delete sound output', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);


    
    if ~vocal
        % Manual weight
        current_tone = neuron_tones(presynaptic_neuron, 1);
        text_w = uicontrol('Style', 'text', 'String', 'Hz (31 to 4978):', 'units', 'normalized', 'position', [0.02 0.69 0.16 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        edit_w = uicontrol('Style', 'edit', 'String', num2str(current_tone), 'units', 'normalized', 'position', [0.18 0.69 0.09 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);    
 
        % Connect
        button_w1 = uicontrol('Style', 'pushbutton', 'String', 'Create sound output synapse', 'units', 'normalized', 'position', [0.02 0.85 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_w1, 'Callback', 'set_synapse_type', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.6 0.95 0.6])

        % Remove
        button_w2 = uicontrol('Style', 'pushbutton', 'String', 'Delete sound output synapse', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_w2, 'Callback', 'set_synapse_type', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

    else
        % Sound effects
        current_sound = neuron_tones(presynaptic_neuron, 1);  
        popup_select_sound = uicontrol('Style', 'popup', 'String', audio_pref_names, 'units', 'normalized', 'position', [0.02 0.85 0.16 0.06], 'fontsize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        if current_sound
            popup_select_sound.Value = current_sound;
        end
    end       
    
    % Wait for OK        
    button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.61 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
    waitfor(fig_design, 'UserData', 0)
    delete(button_confirm)    
    
    % Update variables
    if ~vocal
        this_input = str2double(edit_w.String);
    end
    if ~vocal && (~isa(this_input, 'double') || this_input < 0 || this_input > 4978)
        
        this_input = 0;
        disp('Speaker input out of range. Automatically set to zero.')
    end
    speaker_selected = 0;
    if ~vocal
        neuron_tones(presynaptic_neuron, 1) = this_input;
    else
        neuron_tones(presynaptic_neuron, 1) = popup_select_sound.Value;
    end
    neuron_contacts(presynaptic_neuron, 4) = 100; % this is just to get a good axon weight
    if ~vocal && this_input == 0
        neuron_contacts(presynaptic_neuron, 4) = 0;
    end

    % Design action complete
    design_action = 0; % not read at the end, ugly hack

    % Delete buttons
    if ~vocal
        delete(button_w1)
        delete(button_w2)
        delete(text_w)
        delete(edit_w)
    else
        delete(popup_select_sound)
    end
        
    % Delete growth cone
    delete(growth_cone)
    
    % Delete previous heading
    delete(text_heading)    

    % Draw brain
    draw_brain 

    % Clear neurons
    clear presynaptic_neuron
    clear postsynaptic_contact    
    
    % Disable unavailable buttons
    set(button_add_neuron, 'enable', 'on')
    set(button_add_network, 'enable', 'on')
    set(button_return_to_runtime, 'enable', 'on')       
    
end